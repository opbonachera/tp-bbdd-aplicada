CREATE OR ALTER PROCEDURE ddbba.sp_relacionar_inquilinos_uf
    @ruta_archivo VARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;
    -- Cargar el archivo de inquilinos-UF
    PRINT '--- Iniciando importación de datos de inquilino - UF ---';
    
    IF OBJECT_ID('tempdb..#InquilinosUFTemp') IS NOT NULL
        DROP TABLE #InquilinosUFTemp;
    IF OBJECT_ID('tempdb..#TempLimpia') IS NOT NULL
        DROP TABLE #TempLimpia;

    CREATE TABLE #InquilinosUFTemp (
        CVU_CBU VARCHAR(25),
        nombre_consorcio VARCHAR(255),
        id_unidad_funcional INT,
        piso VARCHAR(10),
        depto VARCHAR(10)
    );

    PRINT 'Tabla temporal #InquilinosUFTemp creada.';

    -- Cargar datos desde el CSV usando BULK INSERT
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

    --  Limpieza de datos en la tabla temporal
    UPDATE #InquilinosUFTemp
    SET depto = RTRIM(REPLACE(REPLACE(depto, CHAR(13), ''), CHAR(10), ''));

    UPDATE #InquilinosUFTemp
    SET CVU_CBU = 
        CASE 
            WHEN CHARINDEX('E', CVU_CBU) > 0 THEN --Detecta si el valor está en notacion científica
                FORMAT(CAST(CAST(CVU_CBU AS FLOAT) AS DECIMAL(20,0)), '0') -- Convierte el numero en entero sin decimales
            ELSE CVU_CBU
        END;

	-- Eliminar duplicados en el archivo
    ;WITH SourceDeduplicada AS (
        SELECT 
            iuf.CVU_CBU,
            iuf.nombre_consorcio,
            iuf.id_unidad_funcional,
            iuf.piso,
            iuf.depto,
            -- Asigna un número de fila para duplicados en el archivo
            ROW_NUMBER() OVER(
                PARTITION BY 
                    iuf.CVU_CBU, 
                    iuf.nombre_consorcio, 
                    iuf.id_unidad_funcional
                ORDER BY (SELECT NULL)
            ) AS rn
        FROM #InquilinosUFTemp iuf
    )
    -- Guardamos la data limpia en una nueva tabla temporal
    SELECT *
    INTO #TempLimpia
    FROM SourceDeduplicada
    WHERE rn = 1;

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
    FROM #TempLimpia iuf -- Usamos la tabla limpia
    JOIN ddbba.persona p 
        ON p.cbu = iuf.CVU_CBU
    JOIN ddbba.consorcio c 
        ON c.nombre = iuf.nombre_consorcio
    JOIN ddbba.unidad_funcional uf
        ON uf.id_consorcio = c.id_consorcio
        AND uf.id_unidad_funcional = iuf.id_unidad_funcional
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM ddbba.rol r
            WHERE r.id_unidad_funcional = uf.id_unidad_funcional
              AND r.nro_documento = p.nro_documento
              AND r.tipo_documento = p.tipo_documento
              AND r.nombre_rol = 'inquilino'
              AND r.activo = 1
        );

    --Actualiza el CBU en la unidad funcional
    UPDATE uf
    SET uf.cbu = iuf.CVU_CBU
    FROM ddbba.unidad_funcional uf
    INNER JOIN ddbba.consorcio c 
        ON uf.id_consorcio = c.id_consorcio
    INNER JOIN #TempLimpia iuf -- Usamos la tabla limpia
        ON LTRIM(RTRIM(iuf.nombre_consorcio)) = LTRIM(RTRIM(c.nombre))
        AND uf.id_unidad_funcional = iuf.id_unidad_funcional
        AND ISNULL(LTRIM(RTRIM(uf.piso)), '') = ISNULL(LTRIM(RTRIM(iuf.piso)), '')
	    AND ISNULL(LTRIM(RTRIM(uf.departamento)), '') = ISNULL(LTRIM(RTRIM(iuf.depto)), '');

    DROP TABLE #InquilinosUFTemp;
    DROP TABLE #TempLimpia;
    
    PRINT '--- Proceso de relación Inquilino-UF finalizado ---';
END;
GO