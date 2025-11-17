/*
    ENUNCIADO: Creación de base de datos, esquema y tablas. 
    COMISION: 02-5600
    CURSO: 3641
    NUMERO DE GRUPO: 01
    MATERIA: BASE DE DATOS APLICADA
    INTEGRANTES:
    Bonachera Ornella — 46119546 
    Benitez Jimena — 46097948 
    Arcón Wogelman, Nazareno-44792096
    Perez, Olivia Constanza — 46641730
    Guardia Gabriel — 42364065 
    Arriola Santiago — 41743980 
*/

--CREACION DE LAS TABLAS ,ESQUEMA Y LA BASE DE DATOS
-- Eliminar tablas en orden correcto (respetando dependencias)
DROP TABLE IF EXISTS ddbba.detalle_expensas_por_uf;
DROP TABLE IF EXISTS ddbba.estado_financiero;
DROP TABLE IF EXISTS ddbba.pago;
DROP TABLE IF EXISTS ddbba.envio_expensa;
DROP TABLE IF EXISTS ddbba.cuotas;
DROP TABLE IF EXISTS ddbba.gasto_extraordinario;
DROP TABLE IF EXISTS ddbba.gastos_ordinarios;
DROP TABLE IF EXISTS ddbba.expensa;
DROP TABLE IF EXISTS ddbba.rol;
DROP TABLE IF EXISTS ddbba.unidad_funcional;
DROP TABLE IF EXISTS ddbba.tipo_envio;
DROP TABLE IF EXISTS ddbba.tipo_gasto;
DROP TABLE IF EXISTS ddbba.persona;
DROP TABLE IF EXISTS ddbba.proveedores;
DROP TABLE IF EXISTS ddbba.consorcio;
GO
--se elmina la base de datos
ALTER DATABASE Com5600_Grpo01 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;--ver
use master
DROP database IF EXISTS Com5600_Grupo01;


-- Crear la base de datos y el esquema
CREATE DATABASE Com5600_Grupo01;
GO
USE Com5600_Grupo01;
GO

CREATE SCHEMA ddbba;
GO

-- Tabla consorcio
CREATE TABLE ddbba.consorcio (
    id_consorcio INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50),
    metros_cuadrados INT,
    direccion VARCHAR(100),
    cant_UF SMALLINT
);
GO

-- Tabla proveedores
CREATE TABLE ddbba.proveedores (
    id_proveedores INT PRIMARY KEY IDENTITY(1,1),
    tipo_de_gasto VARCHAR(50),
    descripcion VARCHAR(100),
    detalle VARCHAR(100) NULL,
    nombre_consorcio VARCHAR(100)
);
GO

-- Tabla persona
CREATE TABLE ddbba.persona (
    nro_documento BIGINT,
    tipo_documento VARCHAR(10),
    nombre VARCHAR(50),
    mail VARCHAR(100),
    telefono VARCHAR(20),
    cbu VARCHAR(30),
    PRIMARY KEY (nro_documento, tipo_documento)
);
GO

-- Tabla tipo_gasto
CREATE TABLE ddbba.tipo_gasto (
    id_tipo_gasto INT PRIMARY KEY IDENTITY(1,1),
    detalle VARCHAR(100)
);
GO

-- Tabla tipo_envio
CREATE TABLE ddbba.tipo_envio (
    id_tipo_envio INT PRIMARY KEY IDENTITY(1,1),
    detalle VARCHAR(100)
);
GO

-- Tabla unidad_funcional (PK compuesta)
CREATE TABLE ddbba.unidad_funcional (
    id_unidad_funcional INT NOT NULL,
    id_consorcio INT NOT NULL,
    metros_cuadrados INT,
    piso VARCHAR(2),
    departamento VARCHAR(10),
    cochera BIT DEFAULT 0,
    baulera BIT DEFAULT 0,
    coeficiente FLOAT,
    saldo_anterior decimal(12,3) DEFAULT 0.00,
    cbu VARCHAR(30),
    prorrateo FLOAT DEFAULT 0,
    CONSTRAINT PK_unidad_funcional PRIMARY KEY (id_unidad_funcional, id_consorcio),
    FOREIGN KEY (id_consorcio) REFERENCES ddbba.consorcio(id_consorcio) ON DELETE CASCADE
);
GO

-- Tabla rol
CREATE TABLE ddbba.rol (
    id_rol INT PRIMARY KEY IDENTITY(1,1),
    id_unidad_funcional INT NOT NULL,
    id_consorcio INT NOT NULL,
    nro_documento BIGINT,
    tipo_documento VARCHAR(10),
    nombre_rol VARCHAR(50),
    activo BIT DEFAULT 1,
    fecha_inicio DATE,
    fecha_fin DATE,
    FOREIGN KEY (id_unidad_funcional, id_consorcio) 
        REFERENCES ddbba.unidad_funcional(id_unidad_funcional, id_consorcio) ON DELETE CASCADE,
    FOREIGN KEY (nro_documento, tipo_documento) 
        REFERENCES ddbba.persona(nro_documento, tipo_documento) ON DELETE CASCADE
);
GO

-- Tabla expensa
CREATE TABLE ddbba.expensa (
    id_expensa INT PRIMARY KEY IDENTITY(1,1),
    id_consorcio INT NOT NULL,
    fecha_emision DATE,
    primer_vencimiento DATE,
    segundo_vencimiento DATE,
    FOREIGN KEY (id_consorcio) REFERENCES ddbba.consorcio(id_consorcio) ON DELETE CASCADE
);
GO

-- Tabla gastos_ordinarios
CREATE TABLE ddbba.gastos_ordinarios (
    id_gasto_ordinario INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT,
    id_tipo_gasto INT,
    detalle VARCHAR(200),
    nro_factura VARCHAR(50),
    importe decimal(12,3),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa) ON DELETE CASCADE,
    FOREIGN KEY (id_tipo_gasto) REFERENCES ddbba.tipo_gasto(id_tipo_gasto)
);
GO

-- Tabla gasto_extraordinario
CREATE TABLE ddbba.gasto_extraordinario (
    id_gasto_extraordinario INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT,
    detalle VARCHAR(200),
    total_cuotas INT DEFAULT 1,
    pago_en_cuotas BIT DEFAULT 0,
    importe_total decimal(12,3),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa) ON DELETE CASCADE
);
GO

-- Tabla cuotas
CREATE TABLE ddbba.cuotas (
    id_gasto_extraordinario INT,
    nro_cuota INT,
    PRIMARY KEY (id_gasto_extraordinario, nro_cuota),
    FOREIGN KEY (id_gasto_extraordinario) REFERENCES ddbba.gasto_extraordinario(id_gasto_extraordinario) ON DELETE CASCADE
);
GO

-- Tabla envio_expensa
CREATE TABLE ddbba.envio_expensa (
    id_envio INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT NOT NULL,
    id_unidad_funcional INT NOT NULL,
    id_consorcio INT NOT NULL,
    id_tipo_envio INT NOT NULL,
    destinatario_nro_documento BIGINT,
    destinatario_tipo_documento VARCHAR(10),
    fecha_envio DATETIME,
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa) ON DELETE CASCADE,
    FOREIGN KEY (id_unidad_funcional, id_consorcio) REFERENCES ddbba.unidad_funcional(id_unidad_funcional, id_consorcio),
    FOREIGN KEY (id_tipo_envio) REFERENCES ddbba.tipo_envio(id_tipo_envio),
    FOREIGN KEY (destinatario_nro_documento, destinatario_tipo_documento) 
        REFERENCES ddbba.persona(nro_documento, tipo_documento) ON DELETE CASCADE
);
GO

-- Tabla pago

CREATE TABLE ddbba.pago (
    id_pago INT PRIMARY KEY,
    id_unidad_funcional INT,
    id_consorcio INT,
    id_expensa INT,
    fecha_pago DATETIME,
    monto decimal(12,3),
    cbu_origen VARCHAR(30),
    estado VARCHAR(30),
    FOREIGN KEY (id_unidad_funcional, id_consorcio) REFERENCES ddbba.unidad_funcional(id_unidad_funcional, id_consorcio) ON DELETE CASCADE,
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa)
);
GO

-- Tabla estado_financiero
CREATE TABLE ddbba.estado_financiero (
    id_expensa INT PRIMARY KEY,
    saldo_anterior decimal(12,3),
    ingresos_en_termino decimal(12,3),
    ingresos_adelantados decimal(12,3),
    ingresos_adeudados decimal(12,3),
    egresos_del_mes decimal(12,3),
    saldo_cierre decimal(12,3),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa) ON DELETE CASCADE
);
GO

-- Tabla detalle_expensas_por_uf
CREATE TABLE ddbba.detalle_expensas_por_uf (
    id_detalle INT NOT NULL,
    id_expensa INT NOT NULL,
    id_unidad_funcional INT NOT NULL,
    id_consorcio INT NOT NULL,
    gastos_ordinarios INT,
    gastos_extraordinarios INT,
    deuda INT,
    interes_mora INT,
    monto_total INT,
    PRIMARY KEY (id_detalle, id_expensa, id_unidad_funcional, id_consorcio),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa) ON DELETE CASCADE,
    FOREIGN KEY (id_unidad_funcional, id_consorcio) REFERENCES ddbba.unidad_funcional(id_unidad_funcional, id_consorcio)
);
GO

-------------------------------------------------------------------------------------------------------------------------
--CREACION DE LAS FUNCIONES PARA LOS SP DE IMPORTACION DE ARCHIVOS
----------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ddbba.fn_normalizar_monto (@valor VARCHAR(50))
RETURNS DECIMAL(12,2)
AS
BEGIN

/* En esta funcion recibimos un valor monetario y lo convertimos en decimal(12,2), siguiendo estas reglas:
1) Limpiamos simbolos y espacios (caracteres no deseados)
2) Detectamos si tiene separador decimal
3) Eliminamos todos los separadores
4) Si tenia separador, insertamos el punto decimal
5) Devolvemos el numero normalizado
*/

    DECLARE @resultado NVARCHAR(50);
    DECLARE @tieneSeparador BIT;

    -- 1) Limpiamos caracteres no deseados
    SET @resultado = ddbba.fn_limpiar_espacios(LTRIM(RTRIM(ISNULL(@valor, '')))); --Borra espacios izq, der y entre medio
    SET @resultado = REPLACE(@resultado, '$', ''); --Saca el $ (si lo tuviese)

    -- 2) Detectamos si tiene separador decimal
    SET @tieneSeparador = CASE 
                            WHEN CHARINDEX(',', @resultado) > 0 OR CHARINDEX('.', @resultado) > 0 --CHARINDEX nos busca la primer aparicion del caracter, si es > 0 -> quiere decir que hay por lo menos UNO de los separadores (ya sea coma o punto)
                            THEN 1 
                            ELSE 0 
                          END;

    -- 3) Eliminamos todos los separadores
    SET @resultado = REPLACE(@resultado, ',', '');
    SET @resultado = REPLACE(@resultado, '.', '');

    -- 4) Si tenia separador, insertamos el punto decimal
    IF @tieneSeparador = 1 AND LEN(@resultado) > 2 --En el caso de que tenga tres digitos o mas,
        SET @resultado = STUFF(@resultado, LEN(@resultado) - 1, 0, '.'); --apuntamos a la posicion justo antes de los ultimos dos digitos (asumimos dos digitos decimales)
    --Si el numero tiene uno o dos digitos, entonces no entra al if y cuando castee solo le agrega el .00

    -- 5) Devolvemos el número normalizado
    RETURN ISNULL(TRY_CAST(@resultado AS DECIMAL(12,2)), 0.00); --Trata de castear el texto a decimal, si no puede, devuelve null y lo transformamos a 0.00
END
GO


CREATE OR ALTER FUNCTION ddbba.fn_limpiar_espacios (@valor VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
--- Limpia los espacios de una cadena de caracteres
    DECLARE @resultado VARCHAR(MAX) = @valor;

    SET @resultado = REPLACE(@resultado, CHAR(32), '');
    SET @resultado = REPLACE(@resultado, CHAR(160), '');
    SET @resultado = REPLACE(@resultado, CHAR(9), '');
    SET @resultado = REPLACE(@resultado, CHAR(10), '');
    SET @resultado = REPLACE(@resultado, CHAR(13), '');

    RETURN @resultado;
END
GO

----------------------------------------------------------------------------------------------------------------
--CREACION DE LOS SP PARA LA IMPORTACION DE ARCHIVOS
-----------------------------------------------------------------------
/*ENUNCIADO:CREACION DE SP NECESARIOS PARA LA IMPORTACION DE ARCHIVOS,USO DE SQL DINAMICO
COMISION:02-5600 
CURSO:3641
NUMERO DE GRUPO : 01
MATERIA: BASE DE DATOS APLICADA
INTEGRANTES:
Bonachera Ornella — 46119546 
Benitez Jimena — 46097948 
Arcón Wogelman, Nazareno-44792096
Perez, Olivia Constanza — 46641730
Guardia Gabriel — 42364065 
Arriola Santiago — 41743980 
*/


USE Com5600_Grupo01;
GO
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
    @ruta_archivo VARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '--- Iniciando importación ---';

    -- ==========================================================
    -- 1. Verificar si la tabla temporal existe
    -- ==========================================================
    IF OBJECT_ID('tempdb..##InquilinosTemp_global') IS NULL
        CREATE TABLE ##InquilinosTemp_global (
            Nombre VARCHAR(100),
            Apellido VARCHAR(100),
            DNI BIGINT,
            EmailPersonal VARCHAR(150),
            TelefonoContacto VARCHAR(50),
            CVU_CBU VARCHAR(100),
            Inquilino BIT
        );

    PRINT 'Tabla temporal creada.';

    -- ==========================================================
    -- 2. Cargar el CSV
    -- ==========================================================
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        BULK INSERT ##InquilinosTemp_global
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
                ROW_NUMBER() OVER (PARTITION BY DNI, Inquilino ORDER BY DNI) AS rn
        FROM ##InquilinosTemp_global
        )
    DELETE FROM cte WHERE rn > 1;

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
    FROM ##InquilinosTemp_global t
    WHERE DNI IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM ddbba.persona p WHERE p.nro_documento = t.DNI
      );

    PRINT 'Personas insertadas (sin duplicados).';
    PRINT '--- Importación finalizada correctamente ---';
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

    -- eliminar registros inválidos
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
        piso VARCHAR (50),
        departamento VARCHAR (50),
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
            FIELDTERMINATOR = ''\t'',   -- Tabulación
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
        CASE WHEN UPPER(LTRIM(RTRIM(t.cochera))) IN ('SI','SÍ','1','TRUE') THEN 1 ELSE 0 END,
        CASE WHEN UPPER(LTRIM(RTRIM(t.baulera))) IN ('SI','SÍ','1','TRUE') THEN 1 ELSE 0 END,
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
        CVU_CBU VARCHAR(23),
        nombre_consorcio VARCHAR(80),
        id_unidad_funcional INT,
        piso CHAR(2),
        depto CHAR(2)
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
        CASE 
            WHEN g.Inquilino = 1 THEN 'inquilino'
            ELSE 'propietario'
        END AS nombre_rol,
        p.nro_documento,
        p.tipo_documento,
        1 AS activo,
        GETDATE() AS fecha_inicio
    FROM #TempLimpia iuf -- Usamos la tabla limpia
    JOIN ##InquilinosTemp_global g 
       ON g.CVU_CBU = iuf.CVU_CBU
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
              AND r.nombre_rol = CASE WHEN g.Inquilino = 1 THEN 'inquilino' ELSE 'propietario' END
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
    DROP TABLE ##InquilinosTemp_global;
    
    PRINT '--- Proceso de relación Inquilino-UF finalizado ---';
END;
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
    SET uf.prorrateo = ROUND((CAST(uf.metros_cuadrados AS FLOAT) / tot.total_m2) * 100, 2)
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

-------------------------------------------------------
-- IMPORTA TODOS LOS ARCHIVOS
-------------------------------------------------------
create or alter procedure ddbba.sp_importar_archivos
as
begin	
	exec ddbba.sp_importar_consorcios @ruta_archivo = 'C:\datos varios.xlsx'
	exec ddbba.sp_importar_proveedores @ruta_archivo ='C:\datos varios.xlsx' 
	exec ddbba.sp_importar_pagos @ruta_archivo = 'C:\pagos_consorcios.csv'
	exec ddbba.sp_importar_uf_por_consorcios @ruta_archivo = 'C:\UF por consorcio.txt' 
	exec ddbba.sp_importar_inquilinos_propietarios @ruta_archivo = 'C:\Inquilino-propietarios-datos.csv'
	exec ddbba.sp_importar_servicios @ruta_archivo = 'C:\Servicios.Servicios.json', @anio=2025
    exec ddbba.sp_relacionar_inquilinos_uf @ruta_archivo = 'C:\Inquilino-propietarios-UF.csv'
	exec ddbba.sp_relacionar_pagos
	exec ddbba.sp_actualizar_prorrateo
end


----------------------------------------------------------------------------------------------------------
--CREACION DE LOS SP PARA GENERAR LOS DATOS RANDOM
---------------------------------------------------------------------------------------------------

-- Generar Cuotas Random
CREATE OR ALTER PROCEDURE ddbba.sp_generar_cuotas
AS
BEGIN
    INSERT INTO ddbba.cuotas (nro_cuota, id_gasto_extraordinario)
    SELECT 
        n.nro,
        ge.id_gasto_extraordinario
    FROM ddbba.gasto_extraordinario ge
    CROSS APPLY (
        SELECT TOP (ge.total_cuotas) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS nro
        FROM sys.all_objects
    ) n
    WHERE NOT EXISTS (
        SELECT 1 FROM ddbba.cuotas c
        WHERE c.id_gasto_extraordinario = ge.id_gasto_extraordinario
          AND c.nro_cuota = n.nro
    );
END
GO
----------------------------------------------------------------------------------------------------
-- Generar Envíos de Expensas Random
CREATE OR ALTER PROCEDURE ddbba.sp_generar_envios_expensas
    @CantidadRegistros INT 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @i INT = 1;
    DECLARE @IdExpensa INT;
    DECLARE @IdUF INT;
    DECLARE @IdConsorcio INT;
    DECLARE @IdTipo INT;
    DECLARE @TipoDoc VARCHAR(10);
    DECLARE @Documento BIGINT;
    DECLARE @FechaEnvio DATE;
    
    WHILE @i <= @CantidadRegistros
    BEGIN
        -- Seleccionar IDs random de tablas relacionadas
        SET @IdExpensa = (SELECT TOP 1 id_expensa FROM ddbba.expensa ORDER BY NEWID());
        SET @IdTipo = (SELECT TOP 1 id_tipo_envio FROM ddbba.tipo_envio ORDER BY NEWID());
        SELECT TOP 1 
			  @IdUF = id_unidad_funcional,
			  @IdConsorcio = id_consorcio
	   FROM ddbba.unidad_funcional 
       ORDER BY NEWID();
        
        -- Obtener un documento random de la tabla persona
        SELECT TOP 1 
            @TipoDoc = tipo_documento,
            @Documento = nro_documento
        FROM ddbba.persona
        ORDER BY NEWID();
        
        -- Generar fecha random en los últimos 365 días
        SET @FechaEnvio = DATEADD(DAY, -FLOOR(RAND() * 365), GETDATE());
        
        INSERT INTO ddbba.envio_expensa (
            id_expensa, 
            id_unidad_funcional, 
            id_consorcio,
            id_tipo_envio, 
            destinatario_nro_documento, 
            destinatario_tipo_documento, 
            fecha_envio
        )
        VALUES (
            @IdExpensa, 
            @IdUF, 
            @IdConsorcio,
            @IdTipo, 
            @Documento, 
            @TipoDoc, 
            @FechaEnvio
        );
        
        SET @i = @i + 1;
    END
    
    PRINT 'Se generaron ' + CAST(@CantidadRegistros AS VARCHAR) + ' envíos de expensas random.';
END
GO


----------------------------------------------------------------------------------------
--Generar Gastos Extraordinarios Random

CREATE OR ALTER PROCEDURE ddbba.sp_generar_gastos_extraordinarios
    @CantidadRegistros INT 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @i INT = 1;
    DECLARE @IdExpensa INT;
    DECLARE @Detalle VARCHAR(200);
    DECLARE @TotalCuotas INT;
    DECLARE @PagoEnCuotas BIT;
    DECLARE @ImporteTotal DECIMAL(18,2);
    
    DECLARE @Detalles TABLE (Descripcion VARCHAR(200));
    INSERT INTO @Detalles VALUES 
        ('Pintura de fachada'),
        ('Reparación de ascensor'),
        ('Cambio de bomba de agua'),
        ('Arreglo de portón eléctrico'),
        ('Impermeabilización de terraza'),
        ('Instalación de cámaras de seguridad'),
        ('Reparación de tanque de agua'),
        ('Cambio de medidores'),
        ('Refacción de hall de entrada'),
        ('Arreglo de instalación eléctrica');
    
    WHILE @i <= @CantidadRegistros
    BEGIN
        SET @IdExpensa = (SELECT TOP 1 id_expensa FROM ddbba.expensa ORDER BY NEWID());
        SET @Detalle = (SELECT TOP 1 Descripcion FROM @Detalles ORDER BY NEWID());
        SET @PagoEnCuotas = CASE WHEN RAND() > 0.5 THEN 1 ELSE 0 END;
        SET @TotalCuotas = CASE WHEN @PagoEnCuotas = 1 THEN FLOOR(RAND() * 11) + 2 ELSE 1 END;
        SET @ImporteTotal = ROUND(RAND() * 500000 + 50000, 2);
        
        INSERT INTO ddbba.gasto_extraordinario (id_expensa, detalle, total_cuotas, 
                                           pago_en_cuotas, importe_total)
        VALUES (@IdExpensa, @Detalle, @TotalCuotas, @PagoEnCuotas, @ImporteTotal);
        
        SET @i = @i + 1;
    END
    
    PRINT 'Se generaron ' + CAST(@CantidadRegistros AS VARCHAR) + ' gastos extraordinarios random.';
END
GO

--------------------------------------------------------------------------------------
-- Generar Pagos Random

CREATE OR ALTER PROCEDURE ddbba.sp_generar_pagos
    @CantidadRegistros INT 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @i INT = 1;
    DECLARE @IdPago INT;
    DECLARE @IdUF INT;
    DECLARE @IdConsorcio INT;
    DECLARE @IdExpensa INT;
    DECLARE @Fecha DATE;
    DECLARE @Monto DECIMAL(18,2);
    DECLARE @CbuOrigen VARCHAR(22);
    DECLARE @Estado VARCHAR(20);
    
    -- Obtener el último id_pago existente
    SELECT @IdPago = ISNULL(MAX(id_pago), 0) FROM ddbba.pago;
    
    WHILE @i <= @CantidadRegistros
    BEGIN
        SET @IdPago = @IdPago + 1;
        
        -- Seleccionar unidad funcional y consorcio juntos
        SELECT TOP 1 
            @IdUF = id_unidad_funcional,
            @IdConsorcio = id_consorcio
        FROM ddbba.unidad_funcional 
        ORDER BY NEWID();
        
        -- Seleccionar una expensa asociada al mismo consorcio
        SET @IdExpensa = (
            SELECT TOP 1 id_expensa 
            FROM ddbba.expensa 
            WHERE id_consorcio = @IdConsorcio
            ORDER BY NEWID()
        );

        -- Si no se encontró expensa, elegir cualquiera 
        IF @IdExpensa IS NULL
            SET @IdExpensa = (SELECT TOP 1 id_expensa FROM ddbba.expensa ORDER BY NEWID());

        SET @Fecha = DATEADD(DAY, -FLOOR(RAND() * 180), GETDATE());
        SET @Monto = ROUND(RAND() * 100000 + 5000, 2);
        
        SET @CbuOrigen = (SELECT TOP 1 cbu FROM ddbba.persona WHERE cbu IS NOT NULL ORDER BY NEWID());
        
        IF @CbuOrigen IS NULL
        BEGIN
            SET @CbuOrigen = '';
            DECLARE @j INT = 1;
            WHILE @j <= 22
            BEGIN
                SET @CbuOrigen = @CbuOrigen + CAST(FLOOR(RAND() * 10) AS VARCHAR(1));
                SET @j = @j + 1;
            END
        END
        
        SET @Estado = CASE FLOOR(RAND() * 3)
            WHEN 0 THEN 'Aprobado'
            WHEN 1 THEN 'Pendiente'
            ELSE 'Rechazado'
        END;
        
        INSERT INTO ddbba.pago (
            id_pago,
            id_unidad_funcional,
            id_consorcio,
            id_expensa,
            fecha_pago,
            monto,
            cbu_origen,
            estado
        )
        VALUES (
            @IdPago,
            @IdUF,
            @IdConsorcio,
            @IdExpensa,
            @Fecha,
            @Monto,
            @CbuOrigen,
            @Estado
        );
        
        SET @i = @i + 1;
    END
    
    PRINT 'Se generaron ' + CAST(@CantidadRegistros AS VARCHAR) + ' pagos random.';
END
GO

----------------------------------------------------------------
--Generar Tipos de Envío Random

CREATE OR ALTER PROCEDURE ddbba.sp_generar_tipos_envio_random
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Limpiar tabla si existe datos
    IF EXISTS (SELECT 1 FROM ddbba.tipo_envio)
    BEGIN
        PRINT 'La tabla tipo_envio ya contiene datos. No se insertarán duplicados.';
        RETURN;
    END
    
    INSERT INTO ddbba.tipo_envio (detalle) VALUES
        ('Email'),
        ('WhatsApp');
    
    PRINT 'Se generaron los tipos de envío predefinidos.';
END
GO
---------------------------------------------------------------------------
-- Generar vencimientos de expensas

CREATE OR ALTER PROCEDURE ddbba.sp_generar_vencimientos_expensas
    @dias_primer_vencimiento INT ,  -- Días después de emisión para 1er vencimiento
    @dias_segundo_vencimiento INT   -- Días después de emisión para 2do vencimiento
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Actualizar solo los registros que tienen fecha_emision pero no tienen vencimientos
        UPDATE ddbba.expensa
        SET 
            primer_vencimiento = DATEADD(DAY, @dias_primer_vencimiento, fecha_emision),
            segundo_vencimiento = DATEADD(DAY, @dias_segundo_vencimiento, fecha_emision)
        WHERE 
            fecha_emision IS NOT NULL
            AND (primer_vencimiento IS NULL OR segundo_vencimiento IS NULL);
        
        -- Retornar cantidad de registros actualizados
        DECLARE @registros_actualizados INT = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Mensaje de resultado
        SELECT 
            @registros_actualizados AS RegistrosActualizados,
            'Vencimientos generados correctamente' AS Mensaje;
            
    END TRY
    BEGIN CATCH
        -- En caso de error, hacer rollback
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Retornar información del error
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje,
            ERROR_LINE() AS ErrorLinea;
    END CATCH
END;
GO
--------------------------------------------------------
-- Generar detalle de expensas por uf
CREATE OR ALTER PROCEDURE ddbba.sp_generar_detalle_expensas_por_uf
    @cantidad INT 
AS
BEGIN
    SET NOCOUNT ON;


    DECLARE 
        @i INT = 1,
        @id_detalle INT,
        @id_expensa INT,
        @id_unidad_funcional INT,
        @id_consorcio INT,
        @gastos_ordinarios DECIMAL(12,2),
        @gastos_extraordinarios DECIMAL(12,2),
        @valor_cuota DECIMAL(12,2),
        @fecha_1er_vto DATE,
        @fecha_2do_vto DATE,
        @fecha_pago DATE,
        @interes_mora DECIMAL(5,2),
        @deuda DECIMAL(12,2),
        @monto_total DECIMAL(12,2);

 -- 1. Cargar datos base

    DECLARE @Expensas TABLE (id_expensa INT, fecha_1er_vto DATE, fecha_2do_vto DATE);
    DECLARE @UF TABLE (id_unidad_funcional INT, id_consorcio INT);
    DECLARE @GastoOrd TABLE (monto DECIMAL(12,2));
    DECLARE @GastoExt TABLE (monto DECIMAL(12,2));

    INSERT INTO @Expensas
    SELECT id_expensa, primer_vencimiento, segundo_vencimiento FROM ddbba.expensa;

    INSERT INTO @UF
    SELECT id_unidad_funcional, id_consorcio FROM ddbba.unidad_funcional;

    INSERT INTO @GastoOrd
    SELECT importe FROM ddbba.gastos_ordinarios;

    INSERT INTO @GastoExt
    SELECT importe_total FROM ddbba.gasto_extraordinario;

    IF NOT EXISTS (SELECT 1 FROM @Expensas) OR NOT EXISTS (SELECT 1 FROM @UF)
    BEGIN
        PRINT N' No hay datos suficientes en expensa o unidad_funcional.';
        RETURN;
    END;

 -- 2. Generar registros random

    WHILE @i <= @cantidad
    BEGIN
        -- Seleccionar expensa y UF válidos
        SELECT TOP 1 
            @id_expensa = id_expensa,
            @fecha_1er_vto = fecha_1er_vto,
            @fecha_2do_vto = fecha_2do_vto
        FROM @Expensas ORDER BY NEWID();

        SELECT TOP 1 
            @id_unidad_funcional = id_unidad_funcional,
            @id_consorcio = id_consorcio
        FROM @UF ORDER BY NEWID();

        -- Buscar fecha de pago (si existe)
        SELECT TOP 1 @fecha_pago = fecha_pago
        FROM ddbba.pago
        WHERE id_expensa = @id_expensa
          AND id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio = @id_consorcio;

        IF @fecha_pago IS NULL
            SET @fecha_pago = CAST(GETDATE() AS DATE); -- sin pago: hoy

        -- Gastos ordinarios y extraordinarios
        SELECT TOP 1 @gastos_ordinarios = monto FROM @GastoOrd ORDER BY NEWID();
        SELECT TOP 1 @gastos_extraordinarios = monto FROM @GastoExt ORDER BY NEWID();

        -- Valor de la cuota
        SET @valor_cuota = @gastos_ordinarios + @gastos_extraordinarios;

        -- Interés por mora
        IF @fecha_pago < @fecha_1er_vto
            SET @interes_mora = 0.00;
        ELSE IF @fecha_pago BETWEEN @fecha_1er_vto AND @fecha_2do_vto
            SET @interes_mora = 0.02;
        ELSE
            SET @interes_mora = 0.05;

        -- Calcular deuda y total
        SET @deuda = @valor_cuota * @interes_mora;
        SET @monto_total = @valor_cuota + @deuda;

        -- Insertar en detalle
        INSERT INTO ddbba.detalle_expensas_por_uf (
            id_detalle,
            id_expensa,
            id_unidad_funcional,
            id_consorcio,
            gastos_ordinarios,
            gastos_extraordinarios,
            deuda,
            interes_mora,
            monto_total
        )
        VALUES (
            @i,
            @id_expensa,
            @id_unidad_funcional,
            @id_consorcio,
            @gastos_ordinarios,
            @gastos_extraordinarios,
            @deuda,
            @interes_mora * 100,  -- porcentaje
            @monto_total
        );

        SET @i += 1;
    END;

    PRINT N' Generación de detalle_expensas_por_uf finalizada correctamente.';
END;
GO
------------------------------------------------------------------------------------------
--Generar Estados financieros
CREATE OR ALTER PROCEDURE ddbba.sp_generar_estado_financiero
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Limpiar la tabla de estados anteriores
    DELETE FROM ddbba.estado_financiero;

    -- 2. Insertar los nuevos estados financieros de forma masiva
    INSERT INTO ddbba.estado_financiero (
        id_expensa,
        saldo_anterior,
        ingresos_en_termino,
        ingresos_adelantados,
        ingresos_adeudados,
        egresos_del_mes,
        saldo_cierre
    )
    SELECT
        e.id_expensa,

        -- Saldo anterior = 10% de los egresos del mes
        x.egresos_del_mes * 0.1 AS saldo_anterior,

        -- Ingresos en término
        ISNULL(SUM(CASE 
            WHEN p.fecha_pago BETWEEN e.primer_vencimiento AND e.segundo_vencimiento THEN p.monto 
            ELSE 0 END), 0) AS ingresos_en_termino,

        -- Ingresos adelantados
        ISNULL(SUM(CASE 
            WHEN p.fecha_pago < e.primer_vencimiento THEN p.monto 
            ELSE 0 END), 0) AS ingresos_adelantados,

        -- Ingresos adeudados = (total expensas+saldo anterior) - total pagos
        CASE 
            WHEN ISNULL(SUM(de.monto_total),0) - ISNULL(SUM(p.monto),0) < 0 THEN 0
            ELSE ISNULL(SUM(de.monto_total),0) - ISNULL(SUM(p.monto),0)
        END AS ingresos_adeudados,

        -- Egresos del mes
        x.egresos_del_mes,

        -- Saldo cierre =  ingresos - egresos
        (x.egresos_del_mes * 0.1)
            + ISNULL(SUM(CASE WHEN p.fecha_pago BETWEEN e.primer_vencimiento AND e.segundo_vencimiento THEN p.monto ELSE 0 END), 0)
            + ISNULL(SUM(CASE WHEN p.fecha_pago < e.primer_vencimiento THEN p.monto ELSE 0 END), 0)
            - x.egresos_del_mes
            - CASE 
                WHEN ISNULL(SUM(de.monto_total),0) - ISNULL(SUM(p.monto),0) < 0 THEN 0
                ELSE ISNULL(SUM(de.monto_total),0) - ISNULL(SUM(p.monto),0)
              END AS saldo_cierre

    FROM ddbba.expensa e
    LEFT JOIN (
        SELECT id_expensa, SUM(importe) AS monto FROM ddbba.gastos_ordinarios GROUP BY id_expensa
    ) AS goo ON e.id_expensa = goo.id_expensa
    LEFT JOIN (
        SELECT id_expensa, SUM(importe_total) AS monto FROM ddbba.gasto_extraordinario GROUP BY id_expensa
    ) AS ge ON e.id_expensa = ge.id_expensa
    LEFT JOIN ddbba.pago AS p ON e.id_expensa = p.id_expensa
    LEFT JOIN ddbba.detalle_expensas_por_uf AS de ON e.id_expensa = de.id_expensa

    CROSS APPLY (
        SELECT ISNULL(goo.monto,0) + ISNULL(ge.monto,0) AS egresos_del_mes
    ) AS x

    GROUP BY 
        e.id_expensa,
        e.primer_vencimiento,
        e.segundo_vencimiento,
        x.egresos_del_mes;

    PRINT N'--- Generación de estado financiero finalizada correctamente ---';
END;
GO


CREATE OR ALTER PROCEDURE ddbba.sp_crear_datos_adicionales
as
begin
	
	EXEC ddbba.sp_GenerarTiposEnvioRandom;
	EXEC ddbba.sp_GenerarEnviosExpensas @CantidadRegistros = 10;
	EXEC ddbba.sp_generar_estado_financiero;
	EXEC ddbba.sp_GenerarGastosExtraordinarios @CantidadRegistros = 10;
	EXEC ddbba.sp_GenerarCuotas ;
	EXEC ddbba.sp_GenerarPagos @CantidadRegistros = 10
	EXEC ddbba.sp_generar_vencimientos_expensas @dias_primer_vencimiento=15,@dias_Segundo_vencimiento=20
	EXEC ddbba.sp_generar_detalle_expensas_por_uf @cantidad=10

end;




---------------------------------------------------------------------------------------------------------------
--CREACION DE TODOS LOS SP PARA LOS REPORTES
-------------------------------------------------------------------------------------------------------------

/*
    Reporte 1
    Flujo de caja semanal:
    - Total recaudado por semana
    - Promedio en el periodo
    - Acumulado progresivo
*/

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_1
    @id_consorcio INT = NULL, 
    @anio_desde INT = NULL,   
    @anio_hasta INT = NULL
WITH EXECUTE AS owner
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @where NVARCHAR(MAX) = N' WHERE 1=1 ';

    -- Filtros dinámicos
    IF @id_consorcio IS NOT NULL
        SET @where += N' AND e.id_consorcio = @id_consorcio ';

    IF @anio_desde IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) >= @anio_desde ';

    IF @anio_hasta IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) <= @anio_hasta ';


    SET @sql = N'
        WITH Pagos AS (
            SELECT
                p.id_pago,
                p.monto,
                p.fecha_pago,
                YEAR(p.fecha_pago) AS anio,
                DATEPART(WEEK, p.fecha_pago) AS semana
            FROM ddbba.pago p
            LEFT JOIN ddbba.expensa e ON e.id_expensa = p.id_expensa
            ' + @where + N'
        ),

        TotalSemanal AS (
            SELECT 
                anio,
                semana,
                SUM(monto) AS total_semanal
            FROM Pagos
            GROUP BY anio, semana
        )

        SELECT 
            anio,
            semana,
            total_semanal,
            AVG(total_semanal) OVER () AS promedio_general,
            SUM(total_semanal) OVER (ORDER BY anio, semana) AS acumulado_progresivo
        FROM TotalSemanal
        ORDER BY anio, semana;
    ';

    EXEC sp_executesql 
        @sql,
        N'@id_consorcio INT, @anio_desde INT, @anio_hasta INT',
        @id_consorcio=@id_consorcio,
        @anio_desde=@anio_desde,
        @anio_hasta=@anio_hasta;
END;
GO

----------------------------------------------------------------------------------------------------------
/*
    Reporte 2
    Presente el total de recaudación por mes y departamento en formato de tabla cruzada. 
*/
CREATE OR ALTER PROCEDURE ddbba.sp_reporte_2
    @min  DECIMAL(12,2) = NULL, 
    @max  DECIMAL(12,2) = NULL,
    @anio INT = NULL
WITH EXECUTE AS owner
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cols NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @where NVARCHAR(MAX) = N' WHERE 1=1 ';
    DECLARE @having NVARCHAR(MAX) = N'';

    -- filtro por año
    IF @anio IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) = @anio ';

    -- filtros HAVING
    IF @min IS NOT NULL AND @max IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) BETWEEN @min AND @max ';
    ELSE IF @min IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) >= @min ';
    ELSE IF @max IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) <= @max ';

    -----------------------------------------------------------
    -- SANEAR nombres de departamento para el XML + PIVOT
    -----------------------------------------------------------
    SELECT 
        @cols = STRING_AGG(
                    QUOTENAME(REPLACE(LTRIM(RTRIM(departamento)), ' ', '_')),
                    ','
                 )
    FROM (
        SELECT DISTINCT departamento
        FROM ddbba.unidad_funcional
    ) AS d;

    -----------------------------------------------------------
    -- SQL dinámico
    -----------------------------------------------------------
    SET @sql = N'
        WITH mes_uf_CTE AS (
            SELECT 
                FORMAT(p.fecha_pago, ''yyyy-MM'') AS mes, 
                REPLACE(LTRIM(RTRIM(uf.departamento)), '' '', ''_'') AS departamento,
                SUM(p.monto) AS total_monto
            FROM ddbba.pago p
            JOIN ddbba.unidad_funcional uf  
                ON uf.id_unidad_funcional = p.id_unidad_funcional
            ' + @where + N'
            GROUP BY FORMAT(p.fecha_pago, ''yyyy-MM''), 
                     REPLACE(LTRIM(RTRIM(uf.departamento)), '' '', ''_'')
            ' + @having + N'
        )
        SELECT mes, ' + @cols + N'
        FROM mes_uf_CTE
        PIVOT (
            SUM(total_monto)
            FOR departamento IN (' + @cols + N')
        ) AS tabla_cruzada
        ORDER BY mes
        FOR XML PATH(''Mes''), ROOT(''Recaudacion''), ELEMENTS XSINIL;
    ';

    -----------------------------------------------------------
    -- Ejecutar con parámetros
    -----------------------------------------------------------
    EXEC sp_executesql 
        @sql,
        N'@min DECIMAL(12,2), @max DECIMAL(12,2), @anio INT',
        @min=@min, @max=@max, @anio=@anio;
END;
GO

--------------------------------------------------------------------------------------

 /*
    Reporte 3
    Presente un cuadro cruzado con la recaudación total desagregada según su procedencia
    (ordinario, extraordinario, etc.) según el periodo.
*/
--IMPORTANTE (ANTES DE EJECUTAR EL SP):
--Para ejecutar un llamado a una API desde SQL primero vamos a tener que habilitar ciertos permisos que por default vienen bloqueados
--'Ole Automation Procedures' permite a SQL Server utilizar el controlador OLE para interactuar con los objetos

EXEC sp_configure 'show advanced options', 1;	--Para poder editar los permisos avanzados
RECONFIGURE;
GO
EXEC sp_configure 'Ole Automation Procedures', 1;	--Habilitamos esta opcion avanzada de OLE
RECONFIGURE;
GO

/*
Reporte 3
Presente un cuadro cruzado con la recaudacion total desagregada segun su procedencia (ordinario, extraordinario, etc.) segun el periodo
*/

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_3
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @IdConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Estamos usando una API que devuelve el valor del dolar oficial, blue y el euro en tipo de cambio comprador y vendedor
    --Referencia: https://api.bluelytics.com.ar/

    -- ================================================
    -- Obtener el valor del dolar oficial (value_buy)
    -- ================================================

    --Vamos a convertir el valor total recaudado y sus desgloses a USD oficial, tipo de cambio comprador
    --Para eso, primero armamos el URL del llamado

    DECLARE @url NVARCHAR(256) = 'https://api.bluelytics.com.ar/v2/latest';

    DECLARE @Object INT;
    DECLARE @json TABLE(DATA NVARCHAR(MAX));
    DECLARE @datos NVARCHAR(MAX); --La usaremos para la posterior interpretacion del json
    DECLARE @valor_dolar DECIMAL(10,2);
    DECLARE @fecha_dolar DATETIME2; --Usamos datetime2 porque datetime esta limitada en el rango de anios

    BEGIN TRY
        EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT; -- Creamos una instancia de OLE que nos permite hacer los llamados
        EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE'; -- Definimos algunas propiedades del objeto para hacer una llamada HTTP Get
        EXEC sp_OAMethod @Object, 'SEND';

        --Si el SP devuelve una tabla, lo podemos almacenar con INSERT

        INSERT INTO @json EXEC sp_OAGetProperty @Object, 'ResponseText'; --Obtenemos el valor de la propiedad 'ResponseText' del objeto OLE despues de realizar la consulta
        EXEC sp_OADestroy @Object;

        --Interpretamos el JSON

        SET @datos = (SELECT DATA FROM @json);

        -- Extraemos el valor del dolar y la ultima fecha de actualizacion

        SELECT 
            @valor_dolar = JSON_VALUE(@datos, '$.oficial.value_buy'),
            @fecha_dolar = JSON_VALUE(@datos, '$.last_update');
    END TRY
    BEGIN CATCH
        PRINT 'Error al obtener el valor del dolar. Se usara 1 como valor por defecto.'; --Por si falla
        SET @valor_dolar = 1;
        SET @fecha_dolar = GETDATE();
    END CATCH;

    -- ============================================
    -- Consulta principal de recaudacion
    -- ============================================

    WITH gastos_union AS (
        SELECT

        --Total de Gastos Ordinarios dentro del periodo

            FORMAT(e.fecha_emision, 'yyyy-MM') AS Periodo,
            'Ordinario' AS Tipo,
            gaor.importe AS Importe
        FROM ddbba.expensa e
        INNER JOIN ddbba.gastos_ordinarios gaor 
            ON e.id_expensa = gaor.id_expensa
        WHERE 
            (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)
            AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)

        UNION ALL

        SELECT

        --Total de Gastos Extraordinarios dentro del periodo

            FORMAT(e.fecha_emision, 'yyyy-MM') AS Periodo,
            'Extraordinario' AS Tipo,
            ge.importe_total AS Importe
        FROM ddbba.expensa e
        INNER JOIN ddbba.gasto_extraordinario ge 
            ON e.id_expensa = ge.id_expensa
        WHERE 
            (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)
            AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)
    )

    --Consulta final con los valores desagregados a mostrar

    SELECT 
        Periodo,
        ISNULL([Ordinario], 0) AS Total_Ordinario,
        CAST(ROUND((ISNULL([Ordinario], 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Ordinario_USD, --Casteamos a DECIMAL y redondeamos a dos digitos
        ISNULL([Extraordinario], 0) AS Total_Extraordinario,
        CAST(ROUND((ISNULL(Extraordinario, 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Extraordinario_USD,
        ISNULL([Ordinario], 0) + ISNULL([Extraordinario], 0) AS Total_Recaudado,
        CAST(ROUND((ISNULL([Ordinario], 0) + ISNULL([Extraordinario], 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Recaudado_USD
    FROM gastos_union
    PIVOT (
        SUM(Importe)
        FOR Tipo IN ([Ordinario], [Extraordinario])
    ) AS pvt
    ORDER BY Periodo;


    -- ============================================
    -- Extraer dolar oficial y fecha
    -- ============================================

    --Podemos mostrar el valor del dolar actual y la ultima fecha de actualizacion en una consulta separada
    --para que quien ejecute el reporte este al tanto de que valor se utilizo al momento de ejecutarse el SP

    SELECT 
        CAST(JSON_VALUE(@datos, '$.oficial.value_buy') AS DECIMAL(10,2)) AS Dolar_Oficial_Compra,
        CONVERT(VARCHAR(19), TRY_CAST(JSON_VALUE(@datos, '$.last_update') AS DATETIME2), 120) AS Fecha_Actualizacion

END;

GO

------------------------------------------------------------------------------------------------------
/*
    Reporte 4
    Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos. 
 */

/*Reporte 4 con XML
Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos*/
CREATE OR ALTER PROCEDURE ddbba.sp_reporte_4
    @id_consorcio INT = NULL,  -- filtrar por consorcio
    @AnioDesde INT = NULL,     -- año desde
    @AnioHasta INT = NULL      --  año hasta
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FechaDesde DATE = NULL;
    DECLARE @FechaHasta DATE = NULL;

    -- Rango de fechas
    IF @AnioDesde IS NOT NULL
        SET @FechaDesde = DATEFROMPARTS(@AnioDesde, 1, 1);
    IF @AnioHasta IS NOT NULL
        SET @FechaHasta = DATEFROMPARTS(@AnioHasta, 12, 31);


-- TOP 5 MESES CON MAYORES GASTOS (Ordinarios + Extraordinarios)

    ;WITH GastosUnificados AS (
        SELECT 
            YEAR(e.fecha_emision) AS Anio,
            MONTH(e.fecha_emision) AS Mes,
            gor.importe AS Monto,
            'Ordinario' AS TipoGasto,
            e.id_consorcio
        FROM ddbba.gastos_ordinarios gor
        INNER JOIN ddbba.expensa e ON gor.id_expensa = e.id_expensa
        WHERE 
            (@id_consorcio IS NULL OR e.id_consorcio = @id_consorcio)
            AND (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)

        UNION ALL

        SELECT 
            YEAR(e.fecha_emision) AS Anio,
            MONTH(e.fecha_emision) AS Mes,
            ge.importe_total AS Monto,
            'Extraordinario' AS TipoGasto,
            e.id_consorcio
        FROM ddbba.gasto_extraordinario ge
        INNER JOIN ddbba.expensa e ON ge.id_expensa = e.id_expensa
        WHERE 
            (@id_consorcio IS NULL OR e.id_consorcio = @id_consorcio)
            AND (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)
    ),
    GastosMensuales AS (
        SELECT 
            Anio,
            Mes,
            DATENAME(MONTH, DATEFROMPARTS(Anio, Mes, 1)) AS NombreMes,
            SUM(Monto) AS TotalGastos,
            SUM(CASE WHEN TipoGasto = 'Ordinario' THEN Monto ELSE 0 END) AS GastosOrdinarios,
            SUM(CASE WHEN TipoGasto = 'Extraordinario' THEN Monto ELSE 0 END) AS GastosExtraordinarios,
            COUNT(*) AS CantidadGastos,
            COUNT(CASE WHEN TipoGasto = 'Ordinario' THEN 1 END) AS CantOrdinarios,
            COUNT(CASE WHEN TipoGasto = 'Extraordinario' THEN 1 END) AS CantExtraordinarios
        FROM GastosUnificados
        GROUP BY Anio, Mes
    )
    SELECT TOP 5
        Anio AS [@Anio],
        Mes AS [@Mes],
        NombreMes AS [@NombreMes],
        TotalGastos AS [@TotalGastos],
        GastosOrdinarios AS [@GastosOrdinarios],
        GastosExtraordinarios AS [@GastosExtraordinarios],
        CantidadGastos AS [@CantidadGastos],
        CantOrdinarios AS [@CantOrdinarios],
        CantExtraordinarios AS [@CantExtraordinarios],
        CAST(Anio AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(Mes AS VARCHAR(2)), 2) AS [@PeriodoOrdenado]
    FROM GastosMensuales
    ORDER BY TotalGastos DESC
    FOR XML PATH('Mes'), ROOT('Top5MesesGastos'), TYPE;


--  TOP 5 MESES CON MAYORES INGRESOS

    ;WITH IngresosMensuales AS (
        SELECT 
            YEAR(p.fecha_pago) AS Anio,
            MONTH(p.fecha_pago) AS Mes,
            DATENAME(MONTH, p.fecha_pago) AS NombreMes,
            SUM(p.monto) AS TotalIngresos,
            COUNT(*) AS CantidadPagos,
            COUNT(DISTINCT p.id_unidad_funcional) AS UnidadesPagaron
        FROM ddbba.pago p
        WHERE 
            p.estado = 'Aprobado'
            AND (@id_consorcio IS NULL OR p.id_consorcio = @id_consorcio)
            AND (@FechaDesde IS NULL OR p.fecha_pago >= @FechaDesde)
            AND (@FechaHasta IS NULL OR p.fecha_pago <= @FechaHasta)
        GROUP BY 
            YEAR(p.fecha_pago),
            MONTH(p.fecha_pago),
            DATENAME(MONTH, p.fecha_pago)
    )
    ---genera el XML
    SELECT TOP 5
        Anio AS [@Anio],
        Mes AS [@Mes],
        NombreMes AS [@NombreMes],
        TotalIngresos AS [@TotalIngresos],
        CantidadPagos AS [@CantidadPagos],
        UnidadesPagaron AS [@UnidadesPagaron],
        CAST(Anio AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(Mes AS VARCHAR(2)), 2) AS [@PeriodoOrdenado]
    FROM IngresosMensuales
    ORDER BY TotalIngresos DESC
    FOR XML PATH('Mes'), ROOT('Top5MesesIngresos'), TYPE;

END;
GO


--------------------------------------------------------------------------------------------
/*
    Obtenga los 3 (tres) propietarios con mayor morosidad. Presente información de contacto y
    DNI de los propietarios para que la administración los pueda contactar o remitir el trámite al
    estudio jurídico.
*/
-- 3 (tres) propietarios con mayor morosidad (morosidad = deuda total que tiene un propietario (persona) por las unidades funcionales que posee).

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_5
    @id_consorcio INT = NULL,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL,
    @limite INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@limite)
        p.nro_documento,
        p.tipo_documento,
        p.nombre,
        p.mail,
        p.telefono,
        SUM(ISNULL(depuf.deuda, 0)) AS total_deuda
    FROM ddbba.persona p
    INNER JOIN ddbba.rol r
        ON p.nro_documento = r.nro_documento
        AND p.tipo_documento = r.tipo_documento
        AND r.nombre_rol = 'Propietario'
    INNER JOIN ddbba.unidad_funcional uf
        ON r.id_unidad_funcional = uf.id_unidad_funcional
        AND r.id_consorcio = uf.id_consorcio
    INNER JOIN ddbba.detalle_expensas_por_uf depuf
        ON uf.id_unidad_funcional = depuf.id_unidad_funcional
        AND uf.id_consorcio = depuf.id_consorcio
    INNER JOIN ddbba.expensa e
        ON depuf.id_expensa = e.id_expensa
    WHERE (@id_consorcio IS NULL OR uf.id_consorcio = @id_consorcio)
      AND (@fecha_desde IS NULL OR e.fecha_emision >= @fecha_desde)
      AND (@fecha_hasta IS NULL OR e.fecha_emision <= @fecha_hasta)
    GROUP BY
        p.nro_documento,
        p.tipo_documento,
        p.nombre,
        p.mail,
        p.telefono
    HAVING SUM(ISNULL(depuf.deuda, 0)) > 0
    ORDER BY total_deuda DESC;
END;
GO

-------------------------------------------------------------------------------------------------
/*
    --  Reporte 6
    Muestre las fechas de pagos de expensas ordinarias de cada UF y la cantidad de días que
    pasan entre un pago y el siguiente, para el conjunto examinado.

*/

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_6
    @id_unidad_funcional INT = NULL,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH PagosUnicos AS (
        SELECT DISTINCT
            p.id_unidad_funcional,
            p.id_expensa,
            CAST(p.fecha_pago AS DATE) AS fecha_pago
        FROM ddbba.pago p
        INNER JOIN ddbba.expensa e ON p.id_expensa = e.id_expensa
        INNER JOIN ddbba.gastos_ordinarios go ON e.id_expensa = go.id_expensa
        INNER JOIN ddbba.unidad_funcional uf ON p.id_unidad_funcional = uf.id_unidad_funcional
        WHERE
            (@id_unidad_funcional IS NULL OR p.id_unidad_funcional = @id_unidad_funcional)
            AND (@fecha_desde IS NULL OR p.fecha_pago >= @fecha_desde)
            AND (@fecha_hasta IS NULL OR p.fecha_pago <= @fecha_hasta)
    ),
    PagosConLag AS (
        SELECT
            *,
            LAG(fecha_pago) OVER (PARTITION BY id_unidad_funcional ORDER BY fecha_pago) AS Fecha_Pago_Anterior
        FROM PagosUnicos
    )
    SELECT
        id_unidad_funcional,
        id_expensa,
        fecha_pago,
        Fecha_Pago_Anterior,
        DATEDIFF(DAY, Fecha_Pago_Anterior, fecha_pago) AS Dias_Entre_Pagos
    FROM PagosConLag
    ORDER BY id_unidad_funcional, fecha_pago;
END
GO


------------------------------------------------------------------------------------------------------------
--CREACION DE INDICES
--------------------------------------------------------------------------------------------------------
-- ======================================
-- ÍNDICES PARA OPTIMIZAR sp_reporte_1
-- ======================================

-- 1 Pago: filtro por año y join con expensa
CREATE INDEX IX_pago_fecha_expensa
ON ddbba.pago (fecha_pago, id_expensa)
INCLUDE (monto);

-- 2 Expensa: join con pago y filtro por consorcio
CREATE INDEX IX_expensa_consorcio
ON ddbba.expensa (id_expensa, id_consorcio);

-- 3 Gastos ordinarios: join por expensa
CREATE INDEX IX_gastos_ordinarios_expensa
ON ddbba.gastos_ordinarios (id_expensa, id_gasto_ordinario);

-- 4 Gasto extraordinario: join por expensa
CREATE INDEX IX_gasto_extraordinario_expensa
ON ddbba.gasto_extraordinario (id_expensa, id_gasto_extraordinario);


-- ==================================================
-- ÍNDICES PARA OPTIMIZAR ddbba.sp_reporte_2
-- ==================================================

-- 1 Índice principal sobre pago:
--    mejora los filtros por fecha y joins por unidad funcional.
CREATE INDEX IX_pago_fecha_unidad_monto
ON ddbba.pago (fecha_pago, id_unidad_funcional)
INCLUDE (monto);

-- 2 Índice sobre unidad_funcional:
--    mejora el join y la búsqueda de departamentos únicos.
CREATE INDEX IX_unidad_funcional_departamento
ON ddbba.unidad_funcional (id_unidad_funcional, departamento);


-- ==================================================
-- ÍNDICES PARA OPTIMIZAR ddbba.sp_reporte_3
-- ==================================================

-- Índice para mejorar filtros y joins en expensa
CREATE INDEX IX_expensa_consorcio_fecha 
ON ddbba.expensa (id_consorcio, fecha_emision, id_expensa);

-- Índices para acelerar los joins y SUM en gastos
CREATE INDEX IX_gastos_ordinarios_expensa 
ON ddbba.gastos_ordinarios (id_expensa, importe);

CREATE INDEX IX_gasto_extraordinario_expensa 
ON ddbba.gasto_extraordinario (id_expensa, importe_total);

-- =====================================================
-- ÍNDICES PARA ddbba.sp_reporte_4
-- =====================================================

-- 1 Índice sobre EXPENSA:
-- Mejora las uniones por id_expensa y los filtros por fecha_emision e id_consorcio.
CREATE INDEX IX_expensa_consorcio_fecha
ON ddbba.expensa (id_consorcio, fecha_emision, id_expensa);

-- 2 Índice sobre GASTOS_ORDINARIOS:
-- Optimiza el JOIN con expensa e inclusión del campo importe (usado en SUM).
CREATE INDEX IX_gastos_ordinarios_expensa
ON ddbba.gastos_ordinarios (id_expensa)
INCLUDE (importe);

-- 3 Índice sobre GASTO_EXTRAORDINARIO:
-- Igual que el anterior, para el JOIN y la agregación de importe_total.
CREATE INDEX IX_gasto_extraordinario_expensa
ON ddbba.gasto_extraordinario (id_expensa)
INCLUDE (importe_total);

-- 4 Índice sobre PAGO:
-- Mejora el filtro por consorcio, fecha y estado (Aprobado),
-- además de las funciones YEAR() y MONTH() usadas en los agrupamientos.
CREATE INDEX IX_pago_consorcio_fecha_estado
ON ddbba.pago (id_consorcio, fecha_pago, estado)
INCLUDE (monto, id_unidad_funcional);

-- =====================================================
-- ÍNDICES RECOMENDADOS PARA ddbba.sp_reporte_5
-- =====================================================
-- Mejora los JOINS con unidad funcional y expensa, también optimiza la función SUM()
CREATE INDEX IX_detalle_expensas_por_uf_unidad_consorcio_expensa
ON ddbba.detalle_expensas_por_uf (id_unidad_funcional, id_consorcio, id_expensa)
INCLUDE (deuda);
--Optimiza JOIN id_expensa y busqueda por rango de fechas
CREATE INDEX IX_expensa_fecha_emision
ON ddbba.expensa (fecha_emision)
INCLUDE (id_expensa);
--Optimiza filtros where y JOINs de persona y unidad funcional
CREATE INDEX IX_rol_propietario
ON ddbba.rol (nombre_rol, nro_documento, tipo_documento, id_unidad_funcional, id_consorcio);
--Optimiza JOINs con rol y id expensa por unidad funcional
CREATE INDEX IX_unidad_funcional_consorcio
ON ddbba.unidad_funcional (id_unidad_funcional, id_consorcio);
-- Optimiza JOIN con rol
CREATE INDEX IX_persona_documento
ON ddbba.persona (nro_documento, tipo_documento);

-- ==================================================
-- ÍNDICES PARA OPTIMIZAR ddbba.sp_reporte_6
-- ==================================================

-- Índice para optimizar el filtrado y orden de los pagos por UF, ID expensa y fecha
CREATE INDEX IX_pago_consorcio_uf_fecha
ON ddbba.pago (id_unidad_funcional, id_expensa, fecha_pago);
GO 

/*
ENUNCIADO:CREACION DE SP NECESARIOS PARA LA GENERACION DE REPORTES PEDIDOS
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

use Com5600_Grupo01;
go

/*
    Reporte 1
    Flujo de caja semanal:
    - Total recaudado por semana
    - Promedio en el periodo
    - Acumulado progresivo
*/

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_1
    @id_consorcio INT = NULL, 
    @anio_desde INT = NULL,   
    @anio_hasta INT = NULL
WITH EXECUTE AS owner
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @where NVARCHAR(MAX) = N' WHERE 1=1 ';

    -- Filtros din�micos
    IF @id_consorcio IS NOT NULL
        SET @where += N' AND e.id_consorcio = @id_consorcio ';

    IF @anio_desde IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) >= @anio_desde ';

    IF @anio_hasta IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) <= @anio_hasta ';


    SET @sql = N'
        WITH Pagos AS (
            SELECT
                p.id_pago,
                p.monto,
                p.fecha_pago,
                YEAR(p.fecha_pago) AS anio,
                DATEPART(WEEK, p.fecha_pago) AS semana
            FROM ddbba.pago p
            LEFT JOIN ddbba.expensa e ON e.id_expensa = p.id_expensa
            ' + @where + N'
        ),

        TotalSemanal AS (
            SELECT 
                anio,
                semana,
                SUM(monto) AS total_semanal
            FROM Pagos
            GROUP BY anio, semana
        )

        SELECT 
            anio,
            semana,
            total_semanal,
            AVG(total_semanal) OVER () AS promedio_general,
            SUM(total_semanal) OVER (ORDER BY anio, semana) AS acumulado_progresivo
        FROM TotalSemanal
        ORDER BY anio, semana;
    ';

    EXEC sp_executesql 
        @sql,
        N'@id_consorcio INT, @anio_desde INT, @anio_hasta INT',
        @id_consorcio=@id_consorcio,
        @anio_desde=@anio_desde,
        @anio_hasta=@anio_hasta;
END;
GO

----------------------------------------------------------------------------------------------------------
/*
    Reporte 2
    Presente el total de recaudaci�n por mes y departamento en formato de tabla cruzada. 
*/
CREATE OR ALTER PROCEDURE ddbba.sp_reporte_2
    @min  DECIMAL(12,2) = NULL, 
    @max  DECIMAL(12,2) = NULL,
    @anio INT = NULL
WITH EXECUTE AS owner
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cols NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @where NVARCHAR(MAX) = N' WHERE 1=1 ';
    DECLARE @having NVARCHAR(MAX) = N'';

    -- filtro por a�o
    IF @anio IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) = @anio ';

    -- filtros HAVING
    IF @min IS NOT NULL AND @max IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) BETWEEN @min AND @max ';
    ELSE IF @min IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) >= @min ';
    ELSE IF @max IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) <= @max ';

    -----------------------------------------------------------
    -- SANEAR nombres de departamento para el XML + PIVOT
    -----------------------------------------------------------
    SELECT 
        @cols = STRING_AGG(
                    QUOTENAME(REPLACE(LTRIM(RTRIM(departamento)), ' ', '_')),
                    ','
                 )
    FROM (
        SELECT DISTINCT departamento
        FROM ddbba.unidad_funcional
    ) AS d;

    -----------------------------------------------------------
    -- SQL din�mico
    -----------------------------------------------------------
    SET @sql = N'
        WITH mes_uf_CTE AS (
            SELECT 
                FORMAT(p.fecha_pago, ''yyyy-MM'') AS mes, 
                REPLACE(LTRIM(RTRIM(uf.departamento)), '' '', ''_'') AS departamento,
                SUM(p.monto) AS total_monto
            FROM ddbba.pago p
            JOIN ddbba.unidad_funcional uf  
                ON uf.id_unidad_funcional = p.id_unidad_funcional
            ' + @where + N'
            GROUP BY FORMAT(p.fecha_pago, ''yyyy-MM''), 
                     REPLACE(LTRIM(RTRIM(uf.departamento)), '' '', ''_'')
            ' + @having + N'
        )
        SELECT mes, ' + @cols + N'
        FROM mes_uf_CTE
        PIVOT (
            SUM(total_monto)
            FOR departamento IN (' + @cols + N')
        ) AS tabla_cruzada
        ORDER BY mes
        FOR XML PATH(''Mes''), ROOT(''Recaudacion''), ELEMENTS XSINIL;
    ';

    -----------------------------------------------------------
    -- Ejecutar con par�metros
    -----------------------------------------------------------
    EXEC sp_executesql 
        @sql,
        N'@min DECIMAL(12,2), @max DECIMAL(12,2), @anio INT',
        @min=@min, @max=@max, @anio=@anio;
END;
GO

--------------------------------------------------------------------------------------

 /*
    Reporte 3
    Presente un cuadro cruzado con la recaudaci�n total desagregada seg�n su procedencia
    (ordinario, extraordinario, etc.) seg�n el periodo.
*/
--IMPORTANTE (ANTES DE EJECUTAR EL SP):
--Para ejecutar un llamado a una API desde SQL primero vamos a tener que habilitar ciertos permisos que por default vienen bloqueados
--'Ole Automation Procedures' permite a SQL Server utilizar el controlador OLE para interactuar con los objetos

EXEC sp_configure 'show advanced options', 1;	--Para poder editar los permisos avanzados
RECONFIGURE;
GO
EXEC sp_configure 'Ole Automation Procedures', 1;	--Habilitamos esta opcion avanzada de OLE
RECONFIGURE;
GO

/*
Reporte 3
Presente un cuadro cruzado con la recaudacion total desagregada segun su procedencia (ordinario, extraordinario, etc.) segun el periodo
*/

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_3
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @IdConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Estamos usando una API que devuelve el valor del dolar oficial, blue y el euro en tipo de cambio comprador y vendedor
    --Referencia: https://api.bluelytics.com.ar/

    -- ================================================
    -- Obtener el valor del dolar oficial (value_buy)
    -- ================================================

    --Vamos a convertir el valor total recaudado y sus desgloses a USD oficial, tipo de cambio comprador
    --Para eso, primero armamos el URL del llamado

    DECLARE @url NVARCHAR(256) = 'https://api.bluelytics.com.ar/v2/latest';

    DECLARE @Object INT;
    DECLARE @json TABLE(DATA NVARCHAR(MAX));
    DECLARE @datos NVARCHAR(MAX); --La usaremos para la posterior interpretacion del json
    DECLARE @valor_dolar DECIMAL(10,2);
    DECLARE @fecha_dolar DATETIME2; --Usamos datetime2 porque datetime esta limitada en el rango de anios

    BEGIN TRY
        EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT; -- Creamos una instancia de OLE que nos permite hacer los llamados
        EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE'; -- Definimos algunas propiedades del objeto para hacer una llamada HTTP Get
        EXEC sp_OAMethod @Object, 'SEND';

        --Si el SP devuelve una tabla, lo podemos almacenar con INSERT

        INSERT INTO @json EXEC sp_OAGetProperty @Object, 'ResponseText'; --Obtenemos el valor de la propiedad 'ResponseText' del objeto OLE despues de realizar la consulta
        EXEC sp_OADestroy @Object;

        --Interpretamos el JSON

        SET @datos = (SELECT DATA FROM @json);

        -- Extraemos el valor del dolar y la ultima fecha de actualizacion

        SELECT 
            @valor_dolar = JSON_VALUE(@datos, '$.oficial.value_buy'),
            @fecha_dolar = JSON_VALUE(@datos, '$.last_update');
    END TRY
    BEGIN CATCH
        PRINT 'Error al obtener el valor del dolar. Se usara 1 como valor por defecto.'; --Por si falla
        SET @valor_dolar = 1;
        SET @fecha_dolar = GETDATE();
    END CATCH;

    -- ============================================
    -- Consulta principal de recaudacion
    -- ============================================

    WITH gastos_union AS (
        SELECT

        --Total de Gastos Ordinarios dentro del periodo

            FORMAT(e.fecha_emision, 'yyyy-MM') AS Periodo,
            'Ordinario' AS Tipo,
            gaor.importe AS Importe
        FROM ddbba.expensa e
        INNER JOIN ddbba.gastos_ordinarios gaor 
            ON e.id_expensa = gaor.id_expensa
        WHERE 
            (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)
            AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)

        UNION ALL

        SELECT

        --Total de Gastos Extraordinarios dentro del periodo

            FORMAT(e.fecha_emision, 'yyyy-MM') AS Periodo,
            'Extraordinario' AS Tipo,
            ge.importe_total AS Importe
        FROM ddbba.expensa e
        INNER JOIN ddbba.gasto_extraordinario ge 
            ON e.id_expensa = ge.id_expensa
        WHERE 
            (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)
            AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)
    )

    --Consulta final con los valores desagregados a mostrar

    SELECT 
        Periodo,
        ISNULL([Ordinario], 0) AS Total_Ordinario,
        CAST(ROUND((ISNULL([Ordinario], 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Ordinario_USD, --Casteamos a DECIMAL y redondeamos a dos digitos
        ISNULL([Extraordinario], 0) AS Total_Extraordinario,
        CAST(ROUND((ISNULL(Extraordinario, 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Extraordinario_USD,
        ISNULL([Ordinario], 0) + ISNULL([Extraordinario], 0) AS Total_Recaudado,
        CAST(ROUND((ISNULL([Ordinario], 0) + ISNULL([Extraordinario], 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Recaudado_USD
    FROM gastos_union
    PIVOT (
        SUM(Importe)
        FOR Tipo IN ([Ordinario], [Extraordinario])
    ) AS pvt
    ORDER BY Periodo;


    -- ============================================
    -- Extraer dolar oficial y fecha
    -- ============================================

    --Podemos mostrar el valor del dolar actual y la ultima fecha de actualizacion en una consulta separada
    --para que quien ejecute el reporte este al tanto de que valor se utilizo al momento de ejecutarse el SP

    SELECT 
        CAST(JSON_VALUE(@datos, '$.oficial.value_buy') AS DECIMAL(10,2)) AS Dolar_Oficial_Compra,
        CONVERT(VARCHAR(19), TRY_CAST(JSON_VALUE(@datos, '$.last_update') AS DATETIME2), 120) AS Fecha_Actualizacion

END;

GO

------------------------------------------------------------------------------------------------------
/*
    Reporte 4
    Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos. 
 */

/*Reporte 4 con XML
Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos*/
CREATE OR ALTER PROCEDURE ddbba.sp_reporte_4
    @id_consorcio INT = NULL,  -- filtrar por consorcio
    @AnioDesde INT = NULL,     -- a�o desde
    @AnioHasta INT = NULL      --  a�o hasta
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FechaDesde DATE = NULL;
    DECLARE @FechaHasta DATE = NULL;

    -- Rango de fechas
    IF @AnioDesde IS NOT NULL
        SET @FechaDesde = DATEFROMPARTS(@AnioDesde, 1, 1);
    IF @AnioHasta IS NOT NULL
        SET @FechaHasta = DATEFROMPARTS(@AnioHasta, 12, 31);


-- TOP 5 MESES CON MAYORES GASTOS (Ordinarios + Extraordinarios)

    ;WITH GastosUnificados AS (
        SELECT 
            YEAR(e.fecha_emision) AS Anio,
            MONTH(e.fecha_emision) AS Mes,
            gor.importe AS Monto,
            'Ordinario' AS TipoGasto,
            e.id_consorcio
        FROM ddbba.gastos_ordinarios gor
        INNER JOIN ddbba.expensa e ON gor.id_expensa = e.id_expensa
        WHERE 
            (@id_consorcio IS NULL OR e.id_consorcio = @id_consorcio)
            AND (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)

        UNION ALL

        SELECT 
            YEAR(e.fecha_emision) AS Anio,
            MONTH(e.fecha_emision) AS Mes,
            ge.importe_total AS Monto,
            'Extraordinario' AS TipoGasto,
            e.id_consorcio
        FROM ddbba.gasto_extraordinario ge
        INNER JOIN ddbba.expensa e ON ge.id_expensa = e.id_expensa
        WHERE 
            (@id_consorcio IS NULL OR e.id_consorcio = @id_consorcio)
            AND (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)
    ),
    GastosMensuales AS (
        SELECT 
            Anio,
            Mes,
            DATENAME(MONTH, DATEFROMPARTS(Anio, Mes, 1)) AS NombreMes,
            SUM(Monto) AS TotalGastos,
            SUM(CASE WHEN TipoGasto = 'Ordinario' THEN Monto ELSE 0 END) AS GastosOrdinarios,
            SUM(CASE WHEN TipoGasto = 'Extraordinario' THEN Monto ELSE 0 END) AS GastosExtraordinarios,
            COUNT(*) AS CantidadGastos,
            COUNT(CASE WHEN TipoGasto = 'Ordinario' THEN 1 END) AS CantOrdinarios,
            COUNT(CASE WHEN TipoGasto = 'Extraordinario' THEN 1 END) AS CantExtraordinarios
        FROM GastosUnificados
        GROUP BY Anio, Mes
    )
    SELECT TOP 5
        Anio AS [@Anio],
        Mes AS [@Mes],
        NombreMes AS [@NombreMes],
        TotalGastos AS [@TotalGastos],
        GastosOrdinarios AS [@GastosOrdinarios],
        GastosExtraordinarios AS [@GastosExtraordinarios],
        CantidadGastos AS [@CantidadGastos],
        CantOrdinarios AS [@CantOrdinarios],
        CantExtraordinarios AS [@CantExtraordinarios],
        CAST(Anio AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(Mes AS VARCHAR(2)), 2) AS [@PeriodoOrdenado]
    FROM GastosMensuales
    ORDER BY TotalGastos DESC
    FOR XML PATH('Mes'), ROOT('Top5MesesGastos'), TYPE;


--  TOP 5 MESES CON MAYORES INGRESOS

    ;WITH IngresosMensuales AS (
        SELECT 
            YEAR(p.fecha_pago) AS Anio,
            MONTH(p.fecha_pago) AS Mes,
            DATENAME(MONTH, p.fecha_pago) AS NombreMes,
            SUM(p.monto) AS TotalIngresos,
            COUNT(*) AS CantidadPagos,
            COUNT(DISTINCT p.id_unidad_funcional) AS UnidadesPagaron
        FROM ddbba.pago p
        WHERE 
            p.estado = 'Aprobado'
            AND (@id_consorcio IS NULL OR p.id_consorcio = @id_consorcio)
            AND (@FechaDesde IS NULL OR p.fecha_pago >= @FechaDesde)
            AND (@FechaHasta IS NULL OR p.fecha_pago <= @FechaHasta)
        GROUP BY 
            YEAR(p.fecha_pago),
            MONTH(p.fecha_pago),
            DATENAME(MONTH, p.fecha_pago)
    )
    ---genera el XML
    SELECT TOP 5
        Anio AS [@Anio],
        Mes AS [@Mes],
        NombreMes AS [@NombreMes],
        TotalIngresos AS [@TotalIngresos],
        CantidadPagos AS [@CantidadPagos],
        UnidadesPagaron AS [@UnidadesPagaron],
        CAST(Anio AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(Mes AS VARCHAR(2)), 2) AS [@PeriodoOrdenado]
    FROM IngresosMensuales
    ORDER BY TotalIngresos DESC
    FOR XML PATH('Mes'), ROOT('Top5MesesIngresos'), TYPE;

END;
GO


--------------------------------------------------------------------------------------------
/*
    Obtenga los 3 (tres) propietarios con mayor morosidad. Presente informaci�n de contacto y
    DNI de los propietarios para que la administraci�n los pueda contactar o remitir el tr�mite al
    estudio jur�dico.
*/
-- 3 (tres) propietarios con mayor morosidad (morosidad = deuda total que tiene un propietario (persona) por las unidades funcionales que posee).

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_5
    @id_consorcio INT = NULL,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL,
    @limite INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@limite)
        p.nro_documento,
        p.tipo_documento,
        p.nombre,
        p.mail,
        p.telefono,
        SUM(ISNULL(depuf.deuda, 0)) AS total_deuda
    FROM ddbba.persona p
    INNER JOIN ddbba.rol r
        ON p.nro_documento = r.nro_documento
        AND p.tipo_documento = r.tipo_documento
        AND r.nombre_rol = 'Propietario'
    INNER JOIN ddbba.unidad_funcional uf
        ON r.id_unidad_funcional = uf.id_unidad_funcional
        AND r.id_consorcio = uf.id_consorcio
    INNER JOIN ddbba.detalle_expensas_por_uf depuf
        ON uf.id_unidad_funcional = depuf.id_unidad_funcional
        AND uf.id_consorcio = depuf.id_consorcio
    INNER JOIN ddbba.expensa e
        ON depuf.id_expensa = e.id_expensa
    WHERE (@id_consorcio IS NULL OR uf.id_consorcio = @id_consorcio)
      AND (@fecha_desde IS NULL OR e.fecha_emision >= @fecha_desde)
      AND (@fecha_hasta IS NULL OR e.fecha_emision <= @fecha_hasta)
    GROUP BY
        p.nro_documento,
        p.tipo_documento,
        p.nombre,
        p.mail,
        p.telefono
    HAVING SUM(ISNULL(depuf.deuda, 0)) > 0
    ORDER BY total_deuda DESC;
END;
GO

-------------------------------------------------------------------------------------------------
/*
    --  Reporte 6
    Muestre las fechas de pagos de expensas ordinarias de cada UF y la cantidad de d�as que
    pasan entre un pago y el siguiente, para el conjunto examinado.

*/

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_6
    @id_unidad_funcional INT = NULL,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH PagosUnicos AS (
        SELECT DISTINCT
            p.id_unidad_funcional,
            p.id_expensa,
            CAST(p.fecha_pago AS DATE) AS fecha_pago
        FROM ddbba.pago p
        INNER JOIN ddbba.expensa e ON p.id_expensa = e.id_expensa
        INNER JOIN ddbba.gastos_ordinarios go ON e.id_expensa = go.id_expensa
        INNER JOIN ddbba.unidad_funcional uf ON p.id_unidad_funcional = uf.id_unidad_funcional
        WHERE
            (@id_unidad_funcional IS NULL OR p.id_unidad_funcional = @id_unidad_funcional)
            AND (@fecha_desde IS NULL OR p.fecha_pago >= @fecha_desde)
            AND (@fecha_hasta IS NULL OR p.fecha_pago <= @fecha_hasta)
    ),
    PagosConLag AS (
        SELECT
            *,
            LAG(fecha_pago) OVER (PARTITION BY id_unidad_funcional ORDER BY fecha_pago) AS Fecha_Pago_Anterior
        FROM PagosUnicos
    )
    SELECT
        id_unidad_funcional,
        id_expensa,
        fecha_pago,
        Fecha_Pago_Anterior,
        DATEDIFF(DAY, Fecha_Pago_Anterior, fecha_pago) AS Dias_Entre_Pagos
    FROM PagosConLag
    ORDER BY id_unidad_funcional, fecha_pago;
END
GO