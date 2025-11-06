
----SP PARA Importar_datos_varios_Consorcios
---ESTO ES PARA IMPORTARLO CON EXCEL
/*CREATE OR ALTER PROCEDURE ddbba.sp_importar_consorcios
	@NomArch varchar(255)
AS
BEGIN
 
--creacion de la tabla temporal
 CREATE TABLE #temp_consorcios
 ( consorcio varchar(12),
   nombre varchar(50),
   domicilio varchar (50),
   cant_UF smallint,
   M2_totales int
  );
--inserto los datos del archivo excel a la tabla temporal con openrowset(lee datos desde un archivo)
--Uso sql dinamico
   DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        INSERT INTO #temp_consorcios (consorcio, nombre, domicilio, cant_UF, M2_totales)
        SELECT Consorcio, [Nombre del consorcio], Domicilio, [Cant unidades funcionales], [m2 totales]
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;Database=' + @NomArch + ';HDR=YES'',
            ''SELECT * FROM [Consorcios$]''
        );
    ';

--ejecuto el sql dinamico
    EXEC sp_executesql @sql;

--Inserto los datos en la tabla original
	INSERT INTO ddbba.consorcio(
    nombre,
    metros_cuadrados ,
    direccion,
	cant_UF
	)
	select
	t.nombre,
	t.M2_totales,
	t.domicilio,
	t.cant_UF

	from #temp_consorcios as t

	--elimino la tabla temporal
	DROP TABLE #temp_consorcios
END
GO
--Para ejecutar el SP
EXEC ddbba.sp_importar_consorcios
	@NomArch='C:\Importar_TP\datos varios.xlsx' --aca va la ruta de donde tengan el archivo


--Para ver si se inserto todo correctamente
select * from ddbba.consorcio


----SP PARA Importar_datos_varios_proveedores

CREATE OR ALTER PROCEDURE ddbba.sp_importar_proveedores
	@NomArch varchar(255)
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
            ''Excel 12.0;Database=' + @NomArch + ';HDR=NO'',
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

--Para ejecutar el SP
EXEC ddbba.sp_importar_proveedores
	@NomArch='C:\Importar_TP\datos varios.xlsx' --aca va la ruta de donde tengan el archivo

--Para ver si se inserto todo correctamente
select * from ddbba.proveedores


--ESTO ES POR SI ALGO NO LES ANDA
--Habilita opciones avanzadas
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

--Habilita consultas ad hoc
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.12.0', 'AllowInProcess', 1;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.12.0', 'DynamicParameters', 1;

--para saber si sql encuentra el archivo
EXEC xp_fileexist 'C:\Importar_TP\datos varios.xlsx';*/
-----------------------------------------------------------------------------

--ESTO ES PARA EXPORTARLO CON CSV
/*USE consorcios;
GO

CREATE OR ALTER PROCEDURE ddbba.sp_importar_consorcios_csv
    @ruta_archivo VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Creación de la tabla temporal (debe coincidir con el CSV de 5 columnas)
    CREATE TABLE #temp_consorcios
     (
        consorcio VARCHAR(12),
        nombre VARCHAR(50),
        domicilio VARCHAR(50),
        cant_UF SMALLINT,
        M2_totales INT
     );

    -- 2. Preparar BULK INSERT (corregido para ; y formato Linux/UTF-8)
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    BULK INSERT #temp_consorcios
    FROM ''' + @ruta_archivo + N'''
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = '';'',     -- Delimitador de punto y coma
        ROWTERMINATOR = ''\n''
    );
    ';

    -- 3. Ejecutar la importación a la tabla temporal
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error durante el BULK INSERT. Verifique la ruta del archivo, los permisos y el formato.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS #temp_consorcios;
        RETURN;
    END CATCH

    -- 4. Inserto los datos en la tabla final (CORREGIDO)
    --    (Se insertan solo las columnas que existen en ddbba.consorcio)
    INSERT INTO ddbba.consorcio (
        nombre,                 -- Columna 'nombre' de la tabla final
        metros_cuadrados,       -- Columna 'metros_cuadrados' de la tabla final
        direccion,
        cant_UF
    )
    SELECT
        t.nombre,               -- Viene de la columna 'nombre' del CSV
        t.M2_totales,           -- Viene de la columna 'm2 totales' del CSV
        t.domicilio,          -- Viene de la columna 'Domicilio' del CSV
        t.cant_UF
    FROM #temp_consorcios AS t
    WHERE NOT EXISTS (
        SELECT 1 FROM ddbba.consorcio c
        where c.nombre = t.nombre
    )

    
END;
GO*/

--ESTO ES PARA EXPORTARLO CON UNA TABLA GLOBAL
/*use "consorcios"
go 

CREATE OR ALTER PROCEDURE ddbba.sp_importar_consorcios
    @NomArch VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- VARIABLES PARA SQL DINÁMICO
    DECLARE @BulkSQL NVARCHAR(MAX);
    DECLARE @DynamicSQL NVARCHAR(MAX);
    
    -- 0. Limpieza y Creación de la tabla temporal GLOBAL (##)
    DROP TABLE IF EXISTS ##temp_consorcios; 
    CREATE TABLE ##temp_consorcios
     (
        consorcio VARCHAR(12),
        nombre VARCHAR(50),
        domicilio VARCHAR(50),
        cant_UF SMALLINT,
        M2_totales INT
     );
    
    -- 1. Definición y Ejecución del BULK INSERT (para cargar el archivo)
    SET @BulkSQL = N'
    BULK INSERT ##temp_consorcios
    FROM ''' + @NomArch + N'''
    WITH
    (
        FIELDTERMINATOR = '';'',  -- Asumo que tu CSV usa punto y coma
        ROWTERMINATOR = ''0x0a'' -- Formato LF para archivos UNIX/Linux
    );';

    BEGIN TRY
        -- Ejecuta la carga del archivo
        EXEC sp_executesql @BulkSQL; 
        
    END TRY
    BEGIN CATCH
        PRINT 'Error durante el BULK INSERT. Verifique la ruta, permisos y formato.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS ##temp_consorcios;
        RETURN;
    END CATCH
    
    -- 2. ELIMINACIÓN DE DUPLICADOS (AHORA DINÁMICO)
    SET @DynamicSQL = N'
        DELETE t
        FROM ##temp_consorcios t  -- 
        WHERE EXISTS (
            SELECT 1
            FROM ddbba.consorcio c
            WHERE c.nombre = t.nombre
        );';
    EXEC sp_executesql @DynamicSQL; -- La compilación se difiere hasta este punto

    -- 3. INSERCIÓN FINAL (AHORA DINÁMICO)
    SET @DynamicSQL = N'
        INSERT INTO ddbba.consorcio (
            nombre,
            metros_cuadrados,
            direccion
        )
        SELECT
            t.nombre,
            t.M2_totales,  
            t.domicilio
        FROM ##temp_consorcios AS t;'; -- ¡CORREGIDO a ## y ejecutado dinámicamente!
    EXEC sp_executesql @DynamicSQL; -- La compilación se difiere hasta este punto
    
    -- 4. Limpia la tabla temporal global al terminar
    DROP TABLE IF EXISTS ##temp_consorcios;

END;
GO



-- 6. Ejecución
EXEC ddbba.sp_importar_consorcios
    @NomArch = 'C:\pruebas\datos_varios(Consorcios).csv';
GO
--Para ejecutar el SP
EXEC ddbba.sp_importar_consorcios
	@NomArch='C:\Users\Usuario\Desktop\TPBASEDDATOS\documentacion\Archivos para el TP\datos_varios(Consorcios).csv' --aca va la ruta de donde tengan el archivo


--Para ver si se inserto todo correctamente
select * from ddbba.consorcio
		
------------------------------------------------------------------------------------------------------------------------
----SP PARA Importar_datos_varios_proveedores
GO





CREATE OR ALTER PROCEDURE ddbba.sp_importar_proveedores
	@NomArch varchar(255) -- Debe contener la ruta COMPLETA del archivo CSV
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables para SQL Dinámico
    DECLARE @BulkSQL NVARCHAR(MAX);
    DECLARE @InsertSQL NVARCHAR(MAX); -- Nueva variable para el INSERT final
    
    -- 0. Limpieza y Creación de la tabla temporal GLOBAL (##)
    DROP TABLE IF EXISTS ##temp_proveedores; 
    
    CREATE TABLE ##temp_proveedores
     (	
        tipo_de_gasto VARCHAR(50),
        descripcion VARCHAR (100),
        detalle VARCHAR(100) NULL,
        nombre_consorcio VARCHAR (255)
     );

    -- 1. Definición y Ejecución del BULK INSERT
    SET @BulkSQL = N'
    BULK INSERT ##temp_proveedores
    FROM ''' + @NomArch + N'''
    WITH
    (
        FIELDTERMINATOR = '';'',     -- Asumo punto y coma
        ROWTERMINATOR = ''0x0a'',  
        FIRSTROW = 2                 -- Asumo que hay encabezados
    );';

    BEGIN TRY
        -- Ejecuta la carga del archivo
        EXEC sp_executesql @BulkSQL; 
        
    END TRY
    BEGIN CATCH
        PRINT 'Error durante el BULK INSERT. Verifique la ruta, permisos y formato.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS ##temp_proveedores;
        RETURN;
    END CATCH
    
    -- 2. Inserto los datos de la tabla temporal a la tabla final (AHORA DINÁMICO)
    --    Esto resuelve el error de "no se pudo enlazar" las columnas.

    SET @InsertSQL = N'
        INSERT INTO ddbba.Proveedores(
            tipo_de_gasto,
            descripcion,
            detalle,
            nombre_consorcio
        )
        SELECT
            t.tipo_de_gasto,
            t.descripcion,
            t.detalle,
            t.nombre_consorcio
        FROM ##temp_proveedores AS t;
    ';

    -- Ejecuta la inserción final
    EXEC sp_executesql @InsertSQL; 

    -- 3. Limpia la tabla temporal global
    DROP TABLE IF EXISTS ##temp_proveedores;
    
END;
GO

--Para ejecutar el SP
EXEC ddbba.sp_importar_proveedores
	@NomArch='C:\pruebas\datos_varios(Proveedores).csv' --aca va la ruta de donde tengan el archivo(si o si tiene que ser en una carpeta disco c para los permisos)

--Para ver si se inserto todo correctamente
select * from ddbba.proveedores
-------------------------------------------------------------------------------------------------------------------------------
--ESTO ES POR SI ALGO NO LES ANDA
--Habilita opciones avanzadas
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

--Habilita consultas ad hoc
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.12.0', 'AllowInProcess', 1;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.12.0', 'DynamicParameters', 1;

--para saber si sql encuentra el archivo
EXEC xp_fileexist 'C:\Users\Usuario\Desktop\TPBASEDDATOS\documentacion\Archivos para el TP\datos varios.xlsx';*/
-----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ddbba.sp_importar_uf_por_consorcios
    @ruta_archivo NVARCHAR(255)
AS
BEGIN
	create table #temp_UF
	(
		nom_consorcio VARCHAR(100),
		num_UF INT,
		piso VARCHAR (10),
		departamento VARCHAR (10),
		coeficiente VARCHAR(10),
		m2_UF INT,
		baulera CHAR(4),
		cochera CHAR(4),
		m2_baulera INT,
		m2_cochera INT
	)


    -- Crear SQL dinámico para BULK INSERT
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'
        BULK INSERT #temp_UF
        FROM ''' + @ruta_archivo + '''
        WITH
        (
            FIELDTERMINATOR = ''\t'',   -- Tabulación
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2       
        );';

    -- Ejecutar SQL dinámico
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error durante el BULK INSERT. Verifique la ruta del archivo, los permisos y el formato.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS #temp_UF;
        RETURN;
    END CATCH
	
	INSERT INTO [ddbba].[unidad_funcional] (
    id_unidad_funcional, id_consorcio, metros_cuadrados, piso, departamento, cochera, baulera, coeficiente
    )
    SELECT  
        t.num_UF,
        c.id_consorcio,
        (t.m2_UF + t.m2_baulera + t.m2_cochera),
        t.piso,
        t.departamento,
        CASE WHEN UPPER(LTRIM(RTRIM(t.cochera))) IN ('SI','SÍ') THEN 1 ELSE 0 END,
        CASE WHEN UPPER(LTRIM(RTRIM(t.baulera))) IN ('SI','SÍ') THEN 1 ELSE 0 END,
        TRY_CAST(REPLACE(t.coeficiente, ',', '.') AS DECIMAL(6,3))
    FROM #temp_UF AS t
    INNER JOIN ddbba.consorcio AS c
        ON LTRIM(RTRIM(UPPER(c.nombre))) = LTRIM(RTRIM(UPPER(t.nom_consorcio)))

	--ELIMINO LA TABLA TEMPORAL
	DROP TABLE #temp_UF
END
GO*
----------------------------------------------------------------------------------------------------------------

---PARA EXPORTAR INQUILINOS-PROPIETARIOS

CREATE OR ALTER PROCEDURE ddbba.sp_importar_inquilinos_propietarios
    @ruta_archivo VARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '--- Iniciando importación ---';

    -- ==========================================================
    -- 1. Verificar si la tabla temporal existe
    -- ==========================================================
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

    PRINT 'Tabla temporal creada.';

    -- ==========================================================
    -- 2. Cargar el CSV
    -- ==========================================================
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        BULK INSERT #InquilinosTemp
        FROM ''' + @ruta_archivo + N'''
        WITH (
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2,
            TABLOCK
        );';
    EXEC(@sql);

    PRINT 'Datos importados en tabla temporal.';

    -- Eliminar duplicados en el archivo
    ;WITH cte AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY DNI ORDER BY DNI) AS rn
        FROM #InquilinosTemp
        )
    DELETE FROM cte WHERE rn > 1;

    UPDATE #InquilinosTemp
    SET CVU_CBU = 
        CASE 
            WHEN CHARINDEX('E', CVU_CBU) > 0 THEN --Detecta si el valor está en notacion científica
                FORMAT(CAST(CAST(CVU_CBU AS FLOAT) AS DECIMAL(20,0)), '0') -- Convierte el numero en entero sin decimales
            ELSE CVU_CBU
    END;

    -- ==========================================================
    -- 3. Insertar en tabla persona sin duplicar
    -- ==========================================================
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

    DROP TABLE #InquilinosTemp
    PRINT 'Personas insertadas (sin duplicados).';
    PRINT '--- Importación finalizada correctamente ---';
END;

----------------------------------------------------------------------------------------------------------------------------------
--PARA EXPORTAR PAGOS
CREATE OR ALTER PROCEDURE ddbba.sp_importar_pagos
    @ruta_archivo NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Importando archivo de pagos'
    -- ==========================================================
    -- 1. Se crea la tabla temporal
    -- ==========================================================
    CREATE TABLE #temp_pagos(
        id_pago INT UNIQUE, 
        fecha DATE,
        cbu VARCHAR(22), 
        valor VARCHAR(50)
    );

    SET DATEFORMAT dmy;

    -- ==========================================================
    -- 2. Se importa el archivo en la tabla temporal
    -- ==========================================================
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        BULK INSERT #temp_pagos
        FROM ''' + @ruta_archivo + N'''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''\n''
        );';

    -- 3. Ejecutar la importación a la tabla temporal
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error durante el BULK INSERT. Verifique la ruta del archivo, los permisos y el formato.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS #temp_consorcios;
        RETURN;
    END CATCH

    -- ==========================================================
    -- 3. Se eliminan los registros vac�os
    -- ==========================================================
    DELETE FROM #temp_pagos
    WHERE fecha IS NULL OR valor IS NULL OR id_pago IS NULL;
    PRINT 'Inserci�n de pagos en la tabla final'
    
    -- ==========================================================
    -- 4. Se insertan los datos del archivo en la tabla de pagos evitando duplicados
    -- ==========================================================
    INSERT INTO ddbba.pago(id_pago, fecha_pago, monto, cbu_origen, estado) 
    SELECT 
        id_pago,
        fecha,
        CAST(ddbba.fn_limpiar_espacios(REPLACE(valor, '$', '')) AS DECIMAL(10,2)) AS monto,
        cbu,
        'no asociado' AS estado
    FROM #temp_pagos
    WHERE NOT EXISTS (
        SELECT 1
        FROM ddbba.pago p
        WHERE p.id_pago = #temp_pagos.id_pago
    );

    PRINT 'Finaliza la importaci�n del archivo de pagos'

    DROP TABLE #temp_pagos;
END;
GO

------------------------------------------------------------------------------------------------
--PARA EXPORTAR SERVICIOS
CREATE OR ALTER PROCEDURE ddbba.sp_importar_servicios
	@ruta_archivo NVARCHAR(500),
    @Anio INT = 2025 --Parametrizamos el anio para poder cambiarlo mas facilmente si lo necesitamos
AS
BEGIN
	
	DECLARE @json NVARCHAR(MAX);
	
    --Usamos SQL dinamico para abrir el JSON
	DECLARE @sql NVARCHAR(MAX);
	SET @sql = N'SELECT @jsonOut = BulkColumn FROM OPENROWSET(BULK ''' + @ruta_archivo + ''', SINGLE_CLOB) AS datos';
	EXEC sp_executesql @SQL, N'@jsonOut NVARCHAR(MAX) OUTPUT', @jsonOut = @json OUTPUT;
	
    --En el caso de que no encuentre el archivo, avisa y termina
    IF @json IS NULL
	BEGIN
		PRINT 'Error: No se pudo leer el archivo JSON.';
		RETURN;
	END

	IF OBJECT_ID('tempdb..#tempConsorcios') IS NOT NULL DROP TABLE #tempConsorcios;

    --Creamos tabla temporal para los consorcios
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

    --Insertamos los datos en la tabla temporal
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

    --Normalizamos el texto (eliminamos espacios de strings y normalizamos valores numericos)
    UPDATE #tempConsorcios
    SET
        nombre_consorcio = nombre_consorcio,
        mes = ddbba.fn_limpiar_espacios(mes),
        bancarios = ddbba.fn_normalizar_monto(bancarios),
        limpieza = ddbba.fn_normalizar_monto(limpieza),
        administracion = ddbba.fn_normalizar_monto(administracion),
        seguros = ddbba.fn_normalizar_monto(seguros),
        gastos_generales = ddbba.fn_normalizar_monto(gastos_generales),
        servicios_agua = ddbba.fn_normalizar_monto(servicios_agua),
        servicios_luz = ddbba.fn_normalizar_monto(servicios_luz),
        servicios_internet = ddbba.fn_normalizar_monto(servicios_internet);

    --Insertamos los tipos de gasto existentes
    INSERT INTO ddbba.tipo_gasto (detalle)
    SELECT detalle
    FROM (VALUES ('BANCARIOS'), ('LIMPIEZA'), ('ADMINISTRACION'), ('SEGUROS'),
           ('GASTOS GENERALES'), ('SERVICIOS PUBLICOS-Agua'), 
           ('SERVICIOS PUBLICOS-Luz'), ('SERVICIOS PUBLICOS-Internet')
    ) AS t(detalle)
    WHERE NOT EXISTS (
        SELECT 1 FROM ddbba.tipo_gasto g WHERE g.detalle = t.detalle
    );

    --Insertamos expensas (una por cada consorcio y mes)
    INSERT INTO ddbba.expensa (id_consorcio, fecha_emision)
    SELECT DISTINCT c.id_consorcio,
     TRY_CONVERT(DATE, CONCAT('01-', m.mes_num, '-', @Anio), 105)
	FROM #tempConsorcios tc
	INNER JOIN ddbba.consorcio c ON c.nombre = tc.nombre_consorcio
	--Creo que para date si o si necesitamos una fecha completa asi que concatenamos con una fecha referencial (el primero del mes) y convertimos el mes a numero usando cross apply
    CROSS APPLY (
        SELECT CASE LOWER(LTRIM(RTRIM(tc.mes)))
            WHEN 'enero' THEN '01'
            WHEN 'febrero' THEN '02'
            WHEN 'marzo' THEN '03'
            WHEN 'abril' THEN '04'
            WHEN 'mayo' THEN '05'
            WHEN 'junio' THEN '06'
            WHEN 'julio' THEN '07'
            WHEN 'agosto' THEN '08'
            WHEN 'septiembre' THEN '09'
            WHEN 'octubre' THEN '10'
            WHEN 'noviembre' THEN '11'
            WHEN 'diciembre' THEN '12'
            ELSE NULL
        END AS mes_num
    ) AS m
    WHERE NOT EXISTS (
		SELECT 1 FROM ddbba.expensa e
		WHERE e.id_consorcio = c.id_consorcio
		  AND e.fecha_emision = TRY_CONVERT(DATE, CONCAT('01-', m.mes_num, '-', @Anio), 105)
        
	);

	-- Insertamos los gastos ordinarios
	-- Insertamos los gastos ordinarios
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
                WHEN 'enero' THEN '01'
                WHEN 'febrero' THEN '02'
                WHEN 'marzo' THEN '03'
                WHEN 'abril' THEN '04'
                WHEN 'mayo' THEN '05'
                WHEN 'junio' THEN '06'
                WHEN 'julio' THEN '07'
                WHEN 'agosto' THEN '08'
                WHEN 'septiembre' THEN '09'
                WHEN 'octubre' THEN '10'
                WHEN 'noviembre' THEN '11'
                WHEN 'diciembre' THEN '12'
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

	PRINT 'Datos importados.';

END
GO


--ejecuto el sp (chequear ruta de archivo)
EXEC ddbba.sp_importar_servicios 
	@ruta_archivo = 'C:\Users\Dell\Documents\base aplicada\tp-bbdd-aplicada\documentacion\Archivos para el TP\Servicios.Servicios.json';
GO

-- EXTRA:
--chequeo que los datos se hayan insertado correctamente
-- SELECT * FROM ddbba.consorcio;
-- SELECT * FROM ddbba.expensa;
-- SELECT * FROM ddbba.tipo_gasto;
-- SELECT count(importe)
-- FROM ddbba.gastos_ordinarios
-- group by importe;
-- GO

-- select sum(importe)
-- from ddbba.gastos_ordinarios
-- group by id_tipo_gasto

-- SELECT 
--     c.nombre AS consorcio,
--     SUM(gaor.importe) AS total_gastos_generales
-- FROM ddbba.gastos_ordinarios gaor
-- INNER JOIN ddbba.expensa e ON e.id_expensa = gaor.id_expensa
-- INNER JOIN ddbba.consorcio c ON c.id_consorcio = e.id_consorcio
-- INNER JOIN ddbba.tipo_gasto tg ON tg.id_tipo_gasto = gaor.id_tipo_gasto
-- WHERE tg.detalle = 'GASTOS GENERALES'
-- GROUP BY c.nombre
-- ORDER BY c.nombre;


-------------------------------------------------------
--PARA EJECUTAR TODOS LOS SP JUNTOS
create or alter procedure ddbba.sp_importar_archivos
as
begin	
	--exec ddbba.sp_importar_consorcios_csv @ruta_archivo = '/app/datasets/tp/datosvarios_consorcios.csv'
	exec ddbba.sp_importar_pagos @ruta_archivo = 'C:\Importar_TP\pagos_consorcios.csv'
	exec ddbba.sp_importar_uf_por_consorcios @ruta_archivo =  'C:\Importar_TP\UF por consorcio.txt'
	exec ddbba.sp_importar_inquilinos_propietarios @ruta_archivo = '‪C:\Importar_TP\Inquilino-propietarios-datos.csv'
	exec ddbba.sp_importar_servicios @ruta_archivo = 'C:\Importar_TP\Servicios.Servicios.json', @anio=2025
	
end

exec ddbba.sp_importar_archivos
