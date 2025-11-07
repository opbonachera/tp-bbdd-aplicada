----------------------------------------------------------------------------------------------
---RELACIONAR INQUILINOS CON SU RESPECTIVA UF
CREATE OR ALTER PROCEDURE ddbba.sp_relacionar_inquilinos_uf
    @ruta_archivo VARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    -- ==========================================================
    -- 1. Cargar el archivo de inquilinos-UF
    -- ========================================================== 
    PRINT '--- Iniciando importación de datos de inquilino - UF ---';
    
    IF OBJECT_ID('tempdb..#InquilinosUFTemp') IS NOT NULL
        DROP TABLE #InquilinosUFTemp;

    CREATE TABLE #InquilinosUFTemp (
        CVU_CBU VARCHAR(25),
        nombre_consorcio VARCHAR(255),
        id_unidad_funcional INT,
        piso VARCHAR(10),
        depto VARCHAR(10)
    );

    PRINT 'Tabla temporal #InquilinosUFTemp creada.';

    -- 2. Cargar datos desde el CSV usando BULK INSERT
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        BULK INSERT #InquilinosUFTemp
        FROM ''' + @ruta_archivo + N'''
        WITH (
            FIELDTERMINATOR = ''|'',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2,
            TABLOCK
        );
    ';

    EXEC sp_executesql @sql;

    -- Elimino el caracter invisible de la columna depto del archivo CSV
    UPDATE #InquilinosUFTemp
    SET depto = RTRIM(REPLACE(REPLACE(depto, CHAR(13), ''), CHAR(10), ''));

    UPDATE #InquilinosUFTemp
    SET CVU_CBU = 
        CASE 
            WHEN CHARINDEX('E', CVU_CBU) > 0 THEN --Detecta si el valor está en notacion científica
                FORMAT(CAST(CAST(CVU_CBU AS FLOAT) AS DECIMAL(20,0)), '0') -- Convierte el numero en entero sin decimales
            ELSE CVU_CBU
        END;

        select * from ddbba.consorcio
        select * from ddbba.persona p 
        select * from ddbba.unidad_funcional uf
        select * from #InquilinosUFTemp iuf
    -- Crear el rol correspondiente
    INSERT INTO ddbba.rol(id_unidad_funcional, id_consorcio, nombre_rol, nro_documento, tipo_documento, activo, fecha_inicio)
    SELECT 
        uf.id_unidad_funcional,
        c.id_consorcio,
        'inquilino' AS nombre_rol,
        p.nro_documento,
        p.tipo_documento,
        1 AS activo,
        GETDATE() AS fecha_inicio
    FROM #InquilinosUFTemp iuf
    JOIN ddbba.persona p 
        ON p.cbu = iuf.CVU_CBU
    JOIN ddbba.consorcio c 
        ON c.nombre = iuf.nombre_consorcio
    JOIN ddbba.unidad_funcional uf
        ON uf.id_consorcio = c.id_consorcio
        AND uf.id_unidad_funcional = iuf.id_unidad_funcional

    -- Actualiza el CBU directamente en la unidad funcional según el archivo importado
     UPDATE uf
    SET uf.cbu = iuf.CVU_CBU
    FROM ddbba.unidad_funcional uf
    INNER JOIN ddbba.consorcio c 
        ON uf.id_consorcio = c.id_consorcio
    INNER JOIN #InquilinosUFTemp iuf 
        ON LTRIM(RTRIM(iuf.nombre_consorcio)) = LTRIM(RTRIM(c.nombre))
        AND uf.id_unidad_funcional = iuf.id_unidad_funcional
        AND ISNULL(LTRIM(RTRIM(uf.piso)), '') = ISNULL(LTRIM(RTRIM(iuf.piso)), '')
        AND ISNULL(LTRIM(RTRIM(uf.departamento)), '') = ISNULL(LTRIM(RTRIM(iuf.depto)), '');

    

    DROP TABLE #InquilinosUFTemp;
END;
GO

----------------------------------------------------------------------------------------------------------------
--Asocia pagos
CREATE OR ALTER PROCEDURE ddbba.sp_relacionar_pagos
AS
BEGIN
    SET NOCOUNT ON;
    PRINT 'Iniciando la asociaci�n de pagos...';

    -- ==========================================================
    -- 1. Actualiza el id de la unidad funcional cuando el CBU del pago coincide con el CBU de la tabla de uf
    -- ==========================================================
    UPDATE p
    SET 
        p.id_unidad_funcional = uf.id_unidad_funcional, -- Asigna el ID de la UF
        p.estado = 'asociado',                           -- Cambia el estado
        p.id_consorcio = uf.id_consorcio
    FROM ddbba.pago AS p
    JOIN ddbba.unidad_funcional AS uf ON p.cbu_origen = uf.cbu
    JOIN ddbba.consorcio AS c on c.id_consorcio = uf.id_consorcio
    -- Solo actualiza los pagos que a�n no est�n asociados
    WHERE 
        p.id_unidad_funcional IS NULL;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' pagos fueron asociados.';
   
END
GO

---------------------------------------------------------------
----ASIGNA EL PRORRATEO

CREATE OR ALTER PROCEDURE ddbba.sp_actualizar_prorrateo
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualiza todos los prorrateos de una sola vez
    UPDATE uf
    SET uf.prorrateo = ROUND((CAST(uf.metros_cuadrados AS FLOAT) / tot.total_m2) * 100, 2)
    FROM ddbba.unidad_funcional AS uf
    INNER JOIN (
        SELECT id_consorcio, SUM(metros_cuadrados) AS total_m2
        FROM ddbba.unidad_funcional
        GROUP BY id_consorcio
    ) AS tot
        ON uf.id_consorcio = tot.id_consorcio;

    PRINT ' Prorrateo actualizado correctamente para todos los consorcios existentes.';
END;

EXEC ddbba.sp_actualizar_prorrateo;

SELECT departamento, metros_cuadrados, prorrateo
FROM ddbba.unidad_funcional
