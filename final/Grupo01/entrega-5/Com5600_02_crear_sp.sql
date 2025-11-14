/*ENUNCIADO:CREACION DE SP NECESARIOS PARA LA IMPORTACION DE ARCHIVOS,USO DE SQL DINAMICO
COMISION:02-5600 
CURSO:3641
NUMERO DE GRUPO : 01
MATERIA: BASE DE DATOS APLICADA
INTEGRANTES:
Bonachera Ornella � 46119546 
Benitez Jimena � 46097948 
Arc�n Wogelman, Nazareno-44792096
Perez, Olivia Constanza � 46641730
Guardia Gabriel � 42364065 
Arriola Santiago � 41743980 
*/

------------------------------------------------------------
-- IMPORTA CONSORCIOS (datos varios.xlsx -> hoja Consorcios)
------------------------------------------------------------
CREATE OR ALTER PROCEDURE ddbba.sp_importar_consorcios
    @ruta_archivo NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #temp_consorcios
    (
        consorcio varchar(50),
        nombre varchar(255),
        domicilio varchar(255),
        cant_UF smallint,
        M2_totales int
    );

    PRINT '--- Iniciando importacion de consorcios ---';
    PRINT 'Insertando en la tabla temporal';

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @ruta_esc NVARCHAR(4000) = REPLACE(@ruta_archivo, '''', '''''');

    SET @sql = N'
        INSERT INTO #temp_consorcios (consorcio, nombre, domicilio, cant_UF, M2_totales)
        SELECT Consorcio, [Nombre del consorcio], Domicilio, [Cant unidades funcionales], [m2 totales]
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;Database=' + @ruta_esc + ';HDR=YES'',
            ''SELECT * FROM [Consorcios$]''
        );';

    EXEC sp_executesql @sql;

    PRINT 'Insertando en la tabla final sin duplicados';

    ;WITH OrigenDeduplicado AS (
        SELECT
            t.nombre,
            t.M2_totales,
            t.domicilio,
            t.cant_UF,
            ROW_NUMBER() OVER (PARTITION BY t.nombre ORDER BY t.consorcio) AS rn
        FROM
            #temp_consorcios AS t
    )
    INSERT INTO ddbba.consorcio (
        nombre,
        metros_cuadrados,
        direccion,
        cant_UF
    )
    SELECT
        od.nombre,
        od.M2_totales,
        od.domicilio,
        od.cant_UF
    FROM OrigenDeduplicado AS od
    WHERE
        od.rn = 1
        AND NOT EXISTS (
            SELECT 1
            FROM ddbba.consorcio AS dest
            WHERE dest.nombre = od.nombre
        );

    PRINT 'Datos importados en la tabla final.';
    PRINT '--- Finaliza importacion de consorcios ---';

    DROP TABLE IF EXISTS #temp_consorcios;
END
GO

------------------------------------------------------------
-- IMPORTA PROVEEDORES (datos varios.xlsx -> hoja Proveedores)
------------------------------------------------------------
CREATE OR ALTER PROCEDURE ddbba.sp_importar_proveedores
	@ruta_archivo varchar(4000)
AS
BEGIN
 
--creacion de la tabla temporal
 CREATE TABLE #temp_proveedores
 (  tipo_de_gasto VARCHAR(50),
	descripcion VARCHAR (100),
	detalle VARCHAR(100) NULL,
	nombre_consorcio VARCHAR (255),
  );
--inserto los datos del archivo excel a la tabla temporal con openrowset(lee datos desde un archivo)
--Uso sql dinamico
   DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        INSERT INTO #temp_proveedores (tipo_de_gasto,descripcion,detalle,nombre_consorcio)
        SELECT F1 as tipo_de_gasto, F2 as descripcion,F3 as detalle, F4 as nombre_consorcio
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;Database=' + @ruta_archivo + ';HDR=NO'',
            ''SELECT * FROM [Proveedores$]''
        );
    ';

--ejecuto el sql dinamico
    EXEC sp_executesql @sql;

--Inserto los datos en la tabla original
	INSERT INTO ddbba.Proveedores(
	tipo_de_gasto,
	descripcion,
	detalle,
	nombre_consorcio
	)
	select
	t.tipo_de_gasto,
	t.descripcion,
	t.detalle,
	t.nombre_consorcio

	from #temp_proveedores as t

	--elimino la tabla temporal
	DROP TABLE #temp_proveedores
END
GO

---------------------------------------------------------------------
-- IMPORTA INQUILINOS Y PROPIETARIOS (Inquilino-propietarios-datos.csv)
---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ddbba.sp_importar_inquilinos_propietarios
    @ruta_archivo NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '--- Iniciando importacion de inquilinos y propietarios ---';

    IF OBJECT_ID('tempdb..#InquilinosTemp') IS NOT NULL
        DROP TABLE #InquilinosTemp;

    CREATE TABLE #InquilinosTemp (
        Nombre VARCHAR(100),
        Apellido VARCHAR(100),
        DNI BIGINT,
        EmailPersonal VARCHAR(150),
        TelefonoContacto VARCHAR(50),
        CVU_CBU VARCHAR(100),
        Inquilino TINYINT
    );

    PRINT 'Insertando en la tabla temporal';
    DECLARE @ruta_esc NVARCHAR(4000) = REPLACE(@ruta_archivo, '''', '''''');
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        BULK INSERT #InquilinosTemp
        FROM ''' + @ruta_esc + N'''
        WITH (
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2,
            TABLOCK
        );';

    EXEC(@sql);
    PRINT 'Datos importados en tabla temporal.';

    ;WITH cte AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY DNI ORDER BY DNI) AS rn
        FROM #InquilinosTemp
    )
    DELETE FROM cte WHERE rn > 1;

    UPDATE #InquilinosTemp
    SET CVU_CBU =
        CASE
            WHEN CHARINDEX('E', CVU_CBU) > 0 AND ISNUMERIC(CVU_CBU) = 1 THEN
                FORMAT(CAST(CAST(CVU_CBU AS FLOAT) AS DECIMAL(20,0)), '0')
            ELSE CVU_CBU
        END;

    PRINT 'Insertando en la tabla final';
    INSERT INTO ddbba.persona (nro_documento, tipo_documento, nombre, mail, telefono, cbu)
    SELECT
        DNI AS nro_documento,
        CASE
            WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'DNI'
            ELSE 'Pasaporte'
        END AS tipo_documento,
        TRIM(UPPER(CONCAT(nombre, ' ', Apellido))) AS nombre,
        REPLACE(TRIM(LOWER(EmailPersonal)), ' ', '') AS mail,
        TelefonoContacto AS telefono,
        CVU_CBU
    FROM #InquilinosTemp t
    WHERE DNI IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM ddbba.persona p WHERE p.nro_documento = t.DNI
      );

    PRINT 'Datos insertados en la tabla final';
    DROP TABLE IF EXISTS #InquilinosTemp;
    PRINT '--- Finaliza importacion de inquilinos y propietarios ---';
END;
GO

---------------------------------------------------------------------
-- IMPORTA PAGOS (Pagos_consorcios.csv)
---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ddbba.sp_importar_pagos
    @ruta_archivo NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '---- Inicia la importacion archivo de pagos ----';

    IF OBJECT_ID('tempdb..#temp_pagos') IS NOT NULL
        DROP TABLE #temp_pagos;

    CREATE TABLE #temp_pagos(
        id_pago INT,
        fecha DATE,
        cbu VARCHAR(50),
        valor VARCHAR(100)
    );

    SET DATEFORMAT dmy;

    DECLARE @ruta_esc NVARCHAR(4000) = REPLACE(@ruta_archivo, '''', '''''');
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        BULK INSERT #temp_pagos
        FROM ''' + @ruta_esc + N'''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''\n'',
            TABLOCK
        );';

    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error durante el BULK INSERT. Verifique la ruta del archivo, los permisos y el formato.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS #temp_pagos;
        RETURN;
    END CATCH;

    -- eliminar registros inv�lidos
    DELETE FROM #temp_pagos
    WHERE fecha IS NULL OR valor IS NULL OR id_pago IS NULL;

    PRINT 'Insertando en la tabla final.';
    INSERT INTO ddbba.pago (id_pago, fecha_pago, monto, cbu_origen, estado)
    SELECT 
        id_pago,
        fecha,
        ddbba.fn_limpiar_espacios(REPLACE(REPLACE(valor, '.', ''), '$', '')) AS monto,
        cbu,
        'no asociado'
    FROM #temp_pagos t
    WHERE NOT EXISTS (
        SELECT 1 FROM ddbba.pago p WHERE p.id_pago = t.id_pago
    );

    PRINT 'Datos insertados en la tabla final.';
    PRINT '---- Finaliza la importacion del archivo de pagos ----';

    DROP TABLE IF EXISTS #temp_pagos;
END;
GO

---------------------------------------------------------------------
-- IMPORTA SERVICIOS (Servicios.servicios.json)
---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ddbba.sp_importar_servicios
    @ruta_archivo NVARCHAR(4000),
    @Anio INT = 2025
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @json NVARCHAR(MAX);
    PRINT '--- Iniciando proceso de importacion de servicios ---';

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @ruta_esc NVARCHAR(4000) = REPLACE(@ruta_archivo, '''', '''''');

    SET @sql = N'SELECT @jsonOut = BulkColumn FROM OPENROWSET(BULK ''' + @ruta_esc + ''', SINGLE_CLOB) AS datos';
    EXEC sp_executesql @sql, N'@jsonOut NVARCHAR(MAX) OUTPUT', @jsonOut = @json OUTPUT;

    IF @json IS NULL
    BEGIN
        PRINT 'Error: No se pudo leer el archivo JSON.';
        RETURN;
    END

    IF OBJECT_ID('tempdb..#tempConsorcios') IS NOT NULL DROP TABLE #tempConsorcios;

    CREATE TABLE #tempConsorcios (
        nombre_consorcio NVARCHAR(255),
        mes NVARCHAR(50),
        bancarios NVARCHAR(50),
        limpieza NVARCHAR(50),
        administracion NVARCHAR(50),
        seguros NVARCHAR(50),
        gastos_generales NVARCHAR(50),
        servicios_agua NVARCHAR(50),
        servicios_luz NVARCHAR(50),
        servicios_internet NVARCHAR(50)
    );

    INSERT INTO #tempConsorcios (nombre_consorcio, mes, bancarios, limpieza, administracion, seguros,
                                 gastos_generales, servicios_agua, servicios_luz, servicios_internet)
    SELECT *
    FROM OPENJSON(@json)
    WITH (
        nombre_consorcio NVARCHAR(255) '$."Nombre del consorcio"',
        mes NVARCHAR(50) '$.Mes',
        bancarios NVARCHAR(50) '$.BANCARIOS',
        limpieza NVARCHAR(50) '$.LIMPIEZA',
        administracion NVARCHAR(50) '$.ADMINISTRACION',
        seguros NVARCHAR(50) '$.SEGUROS',
        gastos_generales NVARCHAR(50) '$."GASTOS GENERALES"',
        servicios_agua NVARCHAR(50) '$."SERVICIOS PUBLICOS-Agua"',
        servicios_luz NVARCHAR(50) '$."SERVICIOS PUBLICOS-Luz"',
        servicios_internet NVARCHAR(50) '$."SERVICIOS PUBLICOS-Internet"'
    );

    -- Normalizar (asumo que existes las funciones indicadas)
    UPDATE #tempConsorcios
    SET
        mes = ddbba.fn_limpiar_espacios(mes),
        bancarios = ddbba.fn_normalizar_monto(bancarios),
        limpieza = ddbba.fn_normalizar_monto(limpieza),
        administracion = ddbba.fn_normalizar_monto(administracion),
        seguros = ddbba.fn_normalizar_monto(seguros),
        gastos_generales = ddbba.fn_normalizar_monto(gastos_generales),
        servicios_agua = ddbba.fn_normalizar_monto(servicios_agua),
        servicios_luz = ddbba.fn_normalizar_monto(servicios_luz),
        servicios_internet = ddbba.fn_normalizar_monto(servicios_internet);

    -- Insertar tipos de gasto (si no existen)
    INSERT INTO ddbba.tipo_gasto (detalle)
    SELECT detalle
    FROM (VALUES ('BANCARIOS'), ('LIMPIEZA'), ('ADMINISTRACION'), ('SEGUROS'),
           ('GASTOS GENERALES'), ('SERVICIOS PUBLICOS-Agua'), 
           ('SERVICIOS PUBLICOS-Luz'), ('SERVICIOS PUBLICOS-Internet')
    ) AS t(detalle)
    WHERE NOT EXISTS (
        SELECT 1 FROM ddbba.tipo_gasto g WHERE g.detalle = t.detalle
    );

    -- Insertar expensas por consorcio/mes
    INSERT INTO ddbba.expensa (id_consorcio, fecha_emision)
    SELECT DISTINCT c.id_consorcio,
        TRY_CONVERT(DATE, CONCAT('01-', m.mes_num, '-', @Anio), 105)
    FROM #tempConsorcios tc
    INNER JOIN ddbba.consorcio c ON c.nombre = tc.nombre_consorcio
    CROSS APPLY (
        SELECT CASE LOWER(LTRIM(RTRIM(tc.mes)))
            WHEN 'enero' THEN '01' WHEN 'febrero' THEN '02' WHEN 'marzo' THEN '03'
            WHEN 'abril' THEN '04' WHEN 'mayo' THEN '05' WHEN 'junio' THEN '06'
            WHEN 'julio' THEN '07' WHEN 'agosto' THEN '08' WHEN 'septiembre' THEN '09'
            WHEN 'octubre' THEN '10' WHEN 'noviembre' THEN '11' WHEN 'diciembre' THEN '12'
            ELSE NULL
        END AS mes_num
    ) AS m
    WHERE NOT EXISTS (
        SELECT 1 FROM ddbba.expensa e
        WHERE e.id_consorcio = c.id_consorcio
          AND e.fecha_emision = TRY_CONVERT(DATE, CONCAT('01-', m.mes_num, '-', @Anio), 105)
    );

    -- Insertar gastos ordinarios (si no existen)
    INSERT INTO ddbba.gastos_ordinarios (id_expensa, id_tipo_gasto, detalle, nro_factura, importe)
    SELECT 
        e.id_expensa,
        t.id_tipo_gasto,
        t.detalle AS detalle,
        NULL AS nro_factura,
        CASE t.detalle
            WHEN 'BANCARIOS' THEN TRY_CAST(tc.bancarios AS DECIMAL(12,2))
            WHEN 'LIMPIEZA' THEN TRY_CAST(tc.limpieza AS DECIMAL(12,2))
            WHEN 'ADMINISTRACION' THEN TRY_CAST(tc.administracion AS DECIMAL(12,2))
            WHEN 'SEGUROS' THEN TRY_CAST(tc.seguros AS DECIMAL(12,2))
            WHEN 'GASTOS GENERALES' THEN TRY_CAST(tc.gastos_generales AS DECIMAL(12,2))
            WHEN 'SERVICIOS PUBLICOS-Agua' THEN TRY_CAST(tc.servicios_agua AS DECIMAL(12,2))
            WHEN 'SERVICIOS PUBLICOS-Luz' THEN TRY_CAST(tc.servicios_luz AS DECIMAL(12,2))
            WHEN 'SERVICIOS PUBLICOS-Internet' THEN TRY_CAST(tc.servicios_internet AS DECIMAL(12,2))
        END AS importe
    FROM #tempConsorcios tc
    INNER JOIN ddbba.consorcio c ON c.nombre = tc.nombre_consorcio
    CROSS APPLY (
        SELECT CASE LOWER(LTRIM(RTRIM(tc.mes)))
            WHEN 'enero' THEN '01' WHEN 'febrero' THEN '02' WHEN 'marzo' THEN '03'
            WHEN 'abril' THEN '04' WHEN 'mayo' THEN '05' WHEN 'junio' THEN '06'
            WHEN 'julio' THEN '07' WHEN 'agosto' THEN '08' WHEN 'septiembre' THEN '09'
            WHEN 'octubre' THEN '10' WHEN 'noviembre' THEN '11' WHEN 'diciembre' THEN '12'
            ELSE NULL
        END AS mes_num
    ) AS m
    INNER JOIN ddbba.expensa e ON e.id_consorcio = c.id_consorcio
        AND e.fecha_emision = TRY_CONVERT(DATE, CONCAT('01-', m.mes_num, '-', @Anio), 105)
    CROSS JOIN ddbba.tipo_gasto t
    WHERE (
        (t.detalle = 'BANCARIOS' AND tc.bancarios IS NOT NULL) OR
        (t.detalle = 'LIMPIEZA' AND tc.limpieza IS NOT NULL) OR
        (t.detalle = 'ADMINISTRACION' AND tc.administracion IS NOT NULL) OR
        (t.detalle = 'SEGUROS' AND tc.seguros IS NOT NULL) OR
        (t.detalle = 'GASTOS GENERALES' AND tc.gastos_generales IS NOT NULL) OR
        (t.detalle = 'SERVICIOS PUBLICOS-Agua' AND tc.servicios_agua IS NOT NULL) OR
        (t.detalle = 'SERVICIOS PUBLICOS-Luz' AND tc.servicios_luz IS NOT NULL) OR
        (t.detalle = 'SERVICIOS PUBLICOS-Internet' AND tc.servicios_internet IS NOT NULL)
    )
    AND NOT EXISTS (
        SELECT 1 FROM ddbba.gastos_ordinarios gaor
        WHERE gaor.id_expensa = e.id_expensa
          AND gaor.id_tipo_gasto = t.id_tipo_gasto
    );

    PRINT '--- Proceso de importacion de servicios finalizado ---';
    DROP TABLE IF EXISTS #tempConsorcios;
END
GO

---------------------------------------------------------------------
-- IMPORTA UNIDADES FUNCIONALES (UF por consorcio.txt)
---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ddbba.sp_importar_uf_por_consorcios
    @ruta_archivo NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#temp_UF') IS NOT NULL
        DROP TABLE #temp_UF;

    CREATE TABLE #temp_UF
    (
        nom_consorcio VARCHAR(255),
        num_UF INT,
        piso CHAR(2),
        departamento CHAR(10),
        coeficiente VARCHAR(50),
        m2_UF INT,
        baulera CHAR(4),
        cochera CHAR(4),
        m2_baulera INT,
        m2_cochera INT
    );

    PRINT '--- Iniciando importacion de unidades funcionales por consorcio ---';
    DECLARE @ruta_esc NVARCHAR(4000) = REPLACE(@ruta_archivo, '''', '''''');
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        BULK INSERT #temp_UF
        FROM ''' + @ruta_esc + N'''
        WITH
        (
            FIELDTERMINATOR = ''\t'',   -- Tabulaci�n
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2,
            TABLOCK
        );';

    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error durante el BULK INSERT. Verifique la ruta del archivo, los permisos y el formato.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS #temp_UF;
        RETURN;
    END CATCH;

    PRINT 'Datos insertados en la tabla temporal.';
    PRINT 'Insertando datos en la tabla final.';

    INSERT INTO ddbba.unidad_funcional (
        id_unidad_funcional, id_consorcio, metros_cuadrados, piso, departamento, cochera, baulera, coeficiente
    )
    SELECT
        t.num_UF,
        c.id_consorcio,
        COALESCE(t.m2_UF,0) + COALESCE(t.m2_baulera,0) + COALESCE(t.m2_cochera,0),
        t.piso,
        t.departamento,
        CASE WHEN UPPER(LTRIM(RTRIM(t.cochera))) IN ('SI','S�','1','TRUE') THEN 1 ELSE 0 END,
        CASE WHEN UPPER(LTRIM(RTRIM(t.baulera))) IN ('SI','S�','1','TRUE') THEN 1 ELSE 0 END,
        TRY_CAST(REPLACE(ISNULL(t.coeficiente,'0'), ',', '.') AS DECIMAL(6,3))
    FROM #temp_UF AS t
    INNER JOIN ddbba.consorcio AS c
        ON LTRIM(RTRIM(UPPER(c.nombre))) = LTRIM(RTRIM(UPPER(t.nom_consorcio)))
    WHERE NOT EXISTS (
        SELECT 1 FROM ddbba.unidad_funcional uf
        WHERE uf.id_consorcio = c.id_consorcio
          AND uf.id_unidad_funcional = t.num_UF
    );

    PRINT 'Datos insertados en la tabla final.';
    PRINT '--- Proceso  importacion de unidades funcionales por consorcio finalizado ---';

    DROP TABLE IF EXISTS #temp_UF;
END
GO

---------------------------------------------------------------------
-- RELACIONA INQUILINOS CON UNIDADES FUNCIONALES (Inquilino-propietarios-UF.csv)
---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ddbba.sp_relacionar_inquilinos_uf
    @ruta_archivo NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '--- Iniciando importaci�n de datos de inquilino - UF ---';

    IF OBJECT_ID('tempdb..#InquilinosUFTemp') IS NOT NULL DROP TABLE #InquilinosUFTemp;
    IF OBJECT_ID('tempdb..#TempLimpia') IS NOT NULL DROP TABLE #TempLimpia;

    CREATE TABLE #InquilinosUFTemp (
        CVU_CBU VARCHAR(100),
        nombre_consorcio VARCHAR(255),
        id_unidad_funcional INT,
        piso VARCHAR(50),
        depto VARCHAR(50)
    );

    DECLARE @ruta_esc NVARCHAR(4000) = REPLACE(@ruta_archivo, '''', '''''');
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        BULK INSERT #InquilinosUFTemp
        FROM ''' + @ruta_esc + N'''
        WITH (
            FIELDTERMINATOR = ''|'',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2,
            TABLOCK
        );';

    EXEC sp_executesql @sql;

    PRINT 'Datos insertados en la tabla temporal.';

    UPDATE #InquilinosUFTemp
    SET depto = RTRIM(REPLACE(REPLACE(depto, CHAR(13), ''), CHAR(10), ''));

    UPDATE #InquilinosUFTemp
    SET CVU_CBU =
        CASE
            WHEN CHARINDEX('E', CVU_CBU) > 0 AND ISNUMERIC(CVU_CBU) = 1 THEN
                FORMAT(CAST(CAST(CVU_CBU AS FLOAT) AS DECIMAL(20,0)), '0')
            ELSE CVU_CBU
        END;

    ;WITH SourceDeduplicada AS (
        SELECT 
            iuf.CVU_CBU,
            iuf.nombre_consorcio,
            iuf.id_unidad_funcional,
            iuf.piso,
            iuf.depto,
            ROW_NUMBER() OVER(
                PARTITION BY 
                    iuf.CVU_CBU, 
                    iuf.nombre_consorcio, 
                    iuf.id_unidad_funcional
                ORDER BY (SELECT NULL)
            ) AS rn
        FROM #InquilinosUFTemp iuf
    )
    SELECT CVU_CBU, nombre_consorcio, id_unidad_funcional, piso, depto
    INTO #TempLimpia
    FROM SourceDeduplicada
    WHERE rn = 1;

    PRINT 'Insertando roles (inquilino) en la tabla final.';
    INSERT INTO ddbba.rol (id_unidad_funcional, id_consorcio, nombre_rol, nro_documento, tipo_documento, activo, fecha_inicio)
    SELECT
        uf.id_unidad_funcional,
        c.id_consorcio,
        'inquilino' AS nombre_rol,
        p.nro_documento,
        p.tipo_documento,
        1 AS activo,
        GETDATE() AS fecha_inicio
    FROM #TempLimpia iuf
    INNER JOIN ddbba.persona p
        ON p.cbu = iuf.CVU_CBU
    INNER JOIN ddbba.consorcio c
        ON LTRIM(RTRIM(c.nombre)) = LTRIM(RTRIM(iuf.nombre_consorcio))
    INNER JOIN ddbba.unidad_funcional uf
        ON uf.id_consorcio = c.id_consorcio
        AND uf.id_unidad_funcional = iuf.id_unidad_funcional
    WHERE NOT EXISTS (
        SELECT 1 FROM ddbba.rol r
        WHERE r.id_unidad_funcional = uf.id_unidad_funcional
          AND r.nro_documento = p.nro_documento
          AND r.tipo_documento = p.tipo_documento
          AND r.nombre_rol = 'inquilino'
          AND r.activo = 1
    );

    PRINT 'Actualizando CBU en unidad funcional (si aplica).';
    UPDATE uf
    SET uf.cbu = iuf.CVU_CBU
    FROM ddbba.unidad_funcional uf
    INNER JOIN ddbba.consorcio c
        ON uf.id_consorcio = c.id_consorcio
    INNER JOIN #TempLimpia iuf
        ON LTRIM(RTRIM(UPPER(iuf.nombre_consorcio))) = LTRIM(RTRIM(UPPER(c.nombre)))
        AND uf.id_unidad_funcional = iuf.id_unidad_funcional
        AND ISNULL(LTRIM(RTRIM(uf.piso)), '') = ISNULL(LTRIM(RTRIM(iuf.piso)), '')
        AND ISNULL(LTRIM(RTRIM(uf.departamento)), '') = ISNULL(LTRIM(RTRIM(iuf.depto)), '');

    DROP TABLE IF EXISTS #InquilinosUFTemp;
    DROP TABLE IF EXISTS #TempLimpia;

    PRINT '--- Proceso de relaci�n Inquilino-UF finalizado ---';
END
GO

---------------------------------------------------------------------
-- RELACIONA PAGOS CON UNIDAD FUNCIONAL
---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ddbba.sp_relacionar_pagos
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '--- Iniciando la asociacion de pagos... ---';

    UPDATE p
    SET 
        p.id_unidad_funcional = uf.id_unidad_funcional,
        p.estado = 'asociado',
        p.id_consorcio = uf.id_consorcio
    FROM ddbba.pago AS p
    JOIN ddbba.unidad_funcional AS uf ON p.cbu_origen = uf.cbu
    WHERE p.id_unidad_funcional IS NULL;

    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' pagos fueron asociados.';
    PRINT '--- Finaliza la asociacion de pagos... ---';
END
GO

---------------------------------------------------------------------
-- GENERA PRORRATEO
---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ddbba.sp_actualizar_prorrateo
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '---- Iniciando calculo de prorrateo por unidad funcional ----';

    UPDATE uf
    SET uf.prorrateo = ROUND((uf.metros_cuadrados * 100.0) / tot.total_m2, 2)
    FROM ddbba.unidad_funcional AS uf
    INNER JOIN (
        SELECT id_consorcio, SUM(metros_cuadrados) AS total_m2
        FROM ddbba.unidad_funcional
        GROUP BY id_consorcio
    ) AS tot
        ON uf.id_consorcio = tot.id_consorcio;

    PRINT '---- Finaliza calculo de prorrateo por unidad funcional ----';
END
GO
