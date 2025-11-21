/*---------------------------------------------------------
 Materia:     Base de datos aplicada. 
 Grupo:       1
 Comision:    5600
 Fecha:       2025-01-01
 Descripcion: Creacion de base de datos, esquema y tablas.
 Integrantes: Arcón Wogelman, Nazareno — 44792096
              Arriola Santiago — 41743980 
              Bonachera Ornella — 46119546
              Benitez Jimena — 46097948
              Guardia Gabriel — 42364065
              Perez, Olivia Constanza — 46641730
----------------------------------------------------------*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  INICIO DEL SCRIPT <<<<<<<<<<<<<<<<<<<<<<<<<<*/
IF DB_ID('Com5600_Grupo01') IS NOT NULL
BEGIN
    USE Com5600_Grupo01;
END
GO

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  ELIMINACION DE BASE DE DATOS Y OBJETOS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*--- Eliminación de índices ---*/
DROP INDEX IF EXISTS IX_pago_fecha_unidad_monto ON finanzas.pago;
DROP INDEX IF EXISTS IX_unidad_funcional_departamento ON consorcios.unidad_funcional;
DROP INDEX IF EXISTS IX_expensa_consorcio_fecha ON finanzas.expensa;
DROP INDEX IF EXISTS IX_gastos_ordinarios_expensa ON finanzas.gasto_ordinario;
DROP INDEX IF EXISTS IX_gasto_extraordinario_expensa ON finanzas.gasto_extraordinario;
DROP INDEX IF EXISTS IX_pago_consorcio_fecha_estado ON finanzas.pago;
DROP INDEX IF EXISTS IX_detalle_expensas_por_uf_unidad_consorcio_expensa ON finanzas.detalle_expensas_por_uf;
DROP INDEX IF EXISTS IX_expensa_fecha_emision ON finanzas.expensa;
DROP INDEX IF EXISTS IX_rol_propietario ON personas.rol;
DROP INDEX IF EXISTS IX_unidad_funcional_consorcio ON consorcios.unidad_funcional;
DROP INDEX IF EXISTS IX_persona_documento ON personas.persona;
DROP INDEX IF EXISTS IX_pago_consorcio_uf_fecha ON finanzas.pago;
GO

/*--- Eliminación de funciones ---*/
DROP FUNCTION IF EXISTS utils.fn_normalizar_monto;
DROP FUNCTION IF EXISTS utils.fn_limpiar_espacios;
GO

/*--- Eliminación de stored procedures ---*/
DROP PROCEDURE IF EXISTS utils.sp_generar_tipos_envio;
DROP PROCEDURE IF EXISTS utils.sp_generar_envios_expensas;
DROP PROCEDURE IF EXISTS utils.sp_generar_estado_financiero;
DROP PROCEDURE IF EXISTS utils.sp_generar_gastos_extraordinarios;
DROP PROCEDURE IF EXISTS utils.sp_generar_cuotas;
DROP PROCEDURE IF EXISTS utils.sp_generar_pagos;
DROP PROCEDURE IF EXISTS utils.sp_generar_vencimientos_expensas;
DROP PROCEDURE IF EXISTS utils.sp_generar_detalle_expensas_por_uf;
DROP PROCEDURE IF EXISTS consorcios.sp_importar_consorcios;
DROP PROCEDURE IF EXISTS personas.sp_importar_proveedores;
DROP PROCEDURE IF EXISTS finanzas.sp_importar_pagos;
DROP PROCEDURE IF EXISTS consorcios.sp_importar_uf_por_consorcios;
DROP PROCEDURE IF EXISTS personas.sp_importar_inquilinos_propietarios;
DROP PROCEDURE IF EXISTS finanzas.sp_importar_servicios;
DROP PROCEDURE IF EXISTS personas.sp_relacionar_inquilinos_uf;
DROP PROCEDURE IF EXISTS finanzas.sp_relacionar_pagos;
DROP PROCEDURE IF EXISTS utils.sp_actualizar_prorrateo;
GO

/*--- Eliminación de tablas ---*/
DROP TABLE IF EXISTS finanzas.detalle_expensas_por_uf;
DROP TABLE IF EXISTS finanzas.estado_financiero;
DROP TABLE IF EXISTS finanzas.pago;
DROP TABLE IF EXISTS gestion.envio_expensa;
DROP TABLE IF EXISTS finanzas.cuota;
DROP TABLE IF EXISTS finanzas.gasto_extraordinario;
DROP TABLE IF EXISTS finanzas.gasto_ordinario;
DROP TABLE IF EXISTS finanzas.expensa;
DROP TABLE IF EXISTS personas.rol;
DROP TABLE IF EXISTS consorcios.unidad_funcional;
DROP TABLE IF EXISTS gestion.tipo_envio;
DROP TABLE IF EXISTS finanzas.tipo_gasto;
DROP TABLE IF EXISTS personas.persona;
DROP TABLE IF EXISTS personas.proveedor;
DROP TABLE IF EXISTS consorcios.consorcio;
GO

/*--- Eliminación de base de datos ---*/
USE master;
ALTER DATABASE Com5600_Grupo01
SET SINGLE_USER WITH ROLLBACK IMMEDIATE; -- Para forzar eliminación aunque haya conexiones

DROP DATABASE Com5600_Grupo01;

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DE ELIMINACION DE BASE DE DATOS Y OBJETOS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CREACION DE LA BASE DE DATOS Y TABLAS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*--- Creación de la db ---*/
CREATE DATABASE Com5600_Grupo01;
GO

USE Com5600_Grupo01;
GO

/*--- Creación de esquemas lógicos ---*/
CREATE SCHEMA consorcios; -- Objetos relacionados a los consorcios y las uf
GO
CREATE SCHEMA personas; --Objetos que manejan datos de personas
GO
CREATE SCHEMA finanzas; -- Objetos relacionados a la gestion financiera del consorcio
GO
CREATE SCHEMA gestion; -- Objetos relacionados a la gestion del consorcio ej. envío de expensas
GO
CREATE SCHEMA utils; -- Objetos que añaden funcionalidades extra, por ejemplo generar datos adicionales
GO
CREATE SCHEMA datos; -- Reportes
GO
CREATE SCHEMA seguridad; -- Objetos relacionados a la seguridad, roles y permisos
GO
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  FIN DE CREACION DE BASE DE DATOS <<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  CREACION DE TABLAS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
CREATE TABLE consorcios.consorcio (
    id_consorcio INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50),
    metros_cuadrados INT,
    direccion VARCHAR(100),
    cant_UF SMALLINT
);
GO

-- Tabla proveedores
CREATE TABLE personas.proveedor (
    id_proveedores INT PRIMARY KEY IDENTITY(1,1),
    tipo_de_gasto VARCHAR(50),
    entidad VARCHAR(100),
    detalle VARCHAR(120) NULL,
    nombre_consorcio VARCHAR(80)
);
GO

-- Tabla persona
CREATE TABLE personas.persona (
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
CREATE TABLE finanzas.tipo_gasto (
    id_tipo_gasto INT PRIMARY KEY IDENTITY(1,1),
    detalle VARCHAR(100)
);
GO

-- Tabla tipo_envio
CREATE TABLE gestion.tipo_envio (
    id_tipo_envio INT PRIMARY KEY IDENTITY(1,1),
    detalle VARCHAR(100)
);
GO

-- Tabla unidad_funcional (PK compuesta)
CREATE TABLE consorcios.unidad_funcional (
    id_unidad_funcional INT NOT NULL,
    id_consorcio INT NOT NULL,
    metros_cuadrados INT,
    piso CHAR(2),
    departamento CHAR(10),
    cochera BIT DEFAULT 0,
    baulera BIT DEFAULT 0,
    coeficiente decimal(12,3),
    saldo_anterior decimal(12,3) DEFAULT 0.00,
    cbu VARCHAR(30),
    prorrateo decimal(12,3) DEFAULT 0.00,
    CONSTRAINT PK_unidad_funcional PRIMARY KEY (id_unidad_funcional, id_consorcio),
    FOREIGN KEY (id_consorcio) REFERENCES consorcios.consorcio(id_consorcio) ON DELETE CASCADE
);
GO

-- Tabla rol
CREATE TABLE personas.rol (
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
        REFERENCES consorcios.unidad_funcional(id_unidad_funcional, id_consorcio) ON DELETE CASCADE,
    FOREIGN KEY (nro_documento, tipo_documento) 
        REFERENCES personas.persona(nro_documento, tipo_documento) ON DELETE CASCADE
);
GO

-- Tabla expensa
CREATE TABLE finanzas.expensa (
    id_expensa INT PRIMARY KEY IDENTITY(1,1),
    id_consorcio INT NOT NULL,
    fecha_emision DATE,
    primer_vencimiento DATE,
    segundo_vencimiento DATE,
    FOREIGN KEY (id_consorcio) REFERENCES consorcios.consorcio(id_consorcio) ON DELETE CASCADE
);
GO

-- Tabla gastos_ordinarios
CREATE TABLE finanzas.gasto_ordinario (
    id_gasto_ordinario INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT,
    id_tipo_gasto INT,
    detalle VARCHAR(200),
    nro_factura VARCHAR(50),
    importe decimal(12,3),
    FOREIGN KEY (id_expensa) REFERENCES finanzas.expensa(id_expensa) ON DELETE CASCADE,
    FOREIGN KEY (id_tipo_gasto) REFERENCES finanzas.tipo_gasto(id_tipo_gasto)
);
GO

-- Tabla gasto_extraordinario
CREATE TABLE finanzas.gasto_extraordinario (
    id_gasto_extraordinario INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT,
    detalle VARCHAR(200),
    total_cuotas INT DEFAULT 1,
    pago_en_cuotas BIT DEFAULT 0,
    importe_total decimal(12,3),
    FOREIGN KEY (id_expensa) REFERENCES finanzas.expensa(id_expensa) ON DELETE CASCADE
);
GO

-- Tabla cuotas
CREATE TABLE finanzas.cuota (
    id_gasto_extraordinario INT,
    nro_cuota INT,
    PRIMARY KEY (id_gasto_extraordinario, nro_cuota),
    FOREIGN KEY (id_gasto_extraordinario) REFERENCES finanzas.gasto_extraordinario(id_gasto_extraordinario) ON DELETE CASCADE
);
GO

-- Tabla envio_expensa
CREATE TABLE gestion.envio_expensa (
    id_envio INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT NOT NULL,
    id_unidad_funcional INT NOT NULL,
    id_consorcio INT NOT NULL,
    id_tipo_envio INT NOT NULL,
    destinatario_nro_documento BIGINT,
    destinatario_tipo_documento VARCHAR(10),
    fecha_envio DATETIME,
    FOREIGN KEY (id_expensa) REFERENCES finanzas.expensa(id_expensa) ON DELETE CASCADE,
    FOREIGN KEY (id_unidad_funcional, id_consorcio) REFERENCES consorcios.unidad_funcional(id_unidad_funcional, id_consorcio),
    FOREIGN KEY (id_tipo_envio) REFERENCES gestion.tipo_envio(id_tipo_envio),
    FOREIGN KEY (destinatario_nro_documento, destinatario_tipo_documento) 
        REFERENCES personas.persona(nro_documento, tipo_documento) ON DELETE CASCADE
);
GO

-- Tabla pago

CREATE TABLE finanzas.pago (
    id_pago INT PRIMARY KEY,
    id_unidad_funcional INT,
    id_consorcio INT,
    id_expensa INT,
    fecha_pago DATETIME,
    monto decimal(12,3),
    cbu_origen VARCHAR(30),
    estado VARCHAR(30),
    FOREIGN KEY (id_unidad_funcional, id_consorcio) REFERENCES consorcios.unidad_funcional(id_unidad_funcional, id_consorcio) ON DELETE CASCADE,
    FOREIGN KEY (id_expensa) REFERENCES finanzas.expensa(id_expensa)
);
GO

-- Tabla estado_financiero
CREATE TABLE finanzas.estado_financiero (
    id_expensa INT PRIMARY KEY,
    saldo_anterior decimal(12,3),
    ingresos_en_termino decimal(12,3),
    ingresos_adelantados decimal(12,3),
    ingresos_adeudados decimal(12,3),
    egresos_del_mes decimal(12,3),
    saldo_cierre decimal(12,3),
    FOREIGN KEY (id_expensa) REFERENCES finanzas.expensa(id_expensa) ON DELETE CASCADE
);
GO

-- Tabla detalle_expensas_por_uf
CREATE TABLE finanzas.detalle_expensas_por_uf (
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
    FOREIGN KEY (id_expensa) REFERENCES finanzas.expensa(id_expensa) ON DELETE CASCADE,
    FOREIGN KEY (id_unidad_funcional, id_consorcio) REFERENCES consorcios.unidad_funcional(id_unidad_funcional, id_consorcio)
);
GO

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  FIN DE CREACION DE TABLAS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  CREACION DE FUNCIONES <<<<<<<<<<<<<<<<<<<<<<<<<<*/
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
    DECLARE @tieneSeparador TINYINT;

    -- 1) Limpiamos caracteres no deseados
    SET @resultado = ddbba.fn_limpiar_espacios(LTRIM(RTRIM(ISNULL(@valor, '')))); --Borra espacios izq, der y entre medio
    SET @resultado = REPLACE(@resultado, '$', ''); --Saca el $ (si lo tuviese)

    -- 2) Detectamos si tiene separador decimal
    SET @resultado = REPLACE(@resultado,',','.');
    SET @tieneSeparador = CHARINDEX('.', REVERSE(@resultado)); --CHARINDEX nos busca la primer aparicion del caracter, si es > 0 -> quiere decir que hay por lo menos UNO de los separadores (ya sea coma o punto)

    -- 3) Eliminamos todos los separadores
   
    

    -- 4) Si tenia separador, insertamos el punto decimal
    IF @tieneSeparador = 3 --En el caso de que tenga tres digitos o mas,
    BEGIN
        SET @resultado = REPLACE(@resultado, '.', '');
        SET @resultado = STUFF(@resultado, LEN(@resultado) - 1, 0, '.'); --apuntamos a la posicion justo antes de los ultimos dos digitos (asumimos dos digitos decimales)
    --Si el numero tiene uno o dos digitos, entonces no entra al if y cuando castee solo le agrega el .00
    END
    ELSE
        SET @resultado = REPLACE(@resultado, '.', '');
    -- 5) Devolvemos el número normalizado
    RETURN ISNULL(TRY_CAST(@resultado AS DECIMAL(12,2)), 0.00); --Trata de castear el texto a decimal, si no puede, devuelve null y lo transformamos a 0.00
END
GO


CREATE OR ALTER FUNCTION utils.fn_limpiar_espacios (@valor VARCHAR(MAX))
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
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  FIN DE CREACION DE FUNCIONES <<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CREACION DE PROCEDIMIENTOS PARA IMPORTAR ARCHIVOS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
-- /* --- IMPORTA CONSORCIOS (datos varios.xlsx -> hoja Consorcios) --- */
CREATE OR ALTER PROCEDURE consorcios.sp_importar_consorcios
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

    PRINT 'Eliminando duplicados en la tabla temporal.';
    -- Se eliminan duplicados en la tabla temporal
    ;WITH D AS (
        SELECT 
               ROW_NUMBER() OVER (
                    PARTITION BY nombre ORDER BY (SELECT NULL)
               ) AS rn
        FROM #temp_consorcios
    )
    DELETE FROM D WHERE rn > 1;
    PRINT 'Duplicados eliminados.';

    INSERT INTO consorcios.consorcio (
        nombre,
        metros_cuadrados,
        direccion,
        cant_UF
    )
    SELECT
        tc.nombre,
        tc.M2_totales,
        tc.domicilio,
        tc.cant_UF
    from #temp_consorcios tc
    WHERE NOT EXISTS (
            SELECT 1
            FROM consorcios.consorcio AS dest
            WHERE dest.nombre = tc.nombre
        );

    PRINT 'Datos importados en la tabla final.';
    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + 'consorcios fueron importados.';
    PRINT '--- Finaliza importacion de consorcios ---';

    DROP TABLE IF EXISTS #temp_consorcios;
END
GO

/* --- IMPORTA PROVEEDORES (datos varios.xlsx -> hoja Proveedores) --- */
CREATE OR ALTER PROCEDURE personas.sp_importar_proveedores
	@ruta_archivo varchar(255)
AS
BEGIN
 
    -- Se crea la tabla temporal
     CREATE TABLE #temp_proveedores
     (  tipo_de_gasto VARCHAR(50),
	    entidad VARCHAR (100),
	    detalle VARCHAR(120) NULL,
	    nombre_consorcio VARCHAR (80),
      );
    --inserto los datos del archivo excel a la tabla temporal con openrowset(lee datos desde un archivo)
    --Uso sql dinamico
       DECLARE @sql NVARCHAR(MAX);

        SET @sql = N'
            INSERT INTO #temp_proveedores (tipo_de_gasto, entidad, detalle, nombre_consorcio)
            SELECT 
                  F1,  -- columna sin encabezado
                  F2,  -- columna sin encabezado
                  F3,  -- columna sin encabezado
                  [Nombre del consorcio]  -- �nica con encabezado
            FROM OPENROWSET(
                 ''Microsoft.ACE.OLEDB.12.0'',
                 ''Excel 12.0;HDR=YES;Database=' + @ruta_archivo + ''',
                 ''SELECT * FROM [Proveedores$]''
            );';

    --ejecuto el sql dinamico
        EXEC sp_executesql @sql;

    --Inserto los datos en la tabla original (sin duplicados)
    INSERT INTO personas.proveedor (
        tipo_de_gasto,
        entidad,
        detalle,
        nombre_consorcio
    )
    SELECT
        t.tipo_de_gasto,
        CASE 
            WHEN LOWER(t.entidad) LIKE '%serv. limpieza%' THEN t.detalle
            ELSE t.entidad
        END AS entidad,
        CASE 
            WHEN LOWER(t.entidad) LIKE '%serv. limpieza%' THEN t.entidad
            ELSE t.detalle
        END AS detalle,
        t.nombre_consorcio
    FROM #temp_proveedores AS t
    WHERE NOT EXISTS (
        SELECT 1
        FROM personas.proveedor p
        WHERE 
            p.tipo_de_gasto = t.tipo_de_gasto
            AND p.entidad = 
                CASE 
                    WHEN LOWER(t.entidad) LIKE '%serv. limpieza%' THEN t.detalle
                    ELSE t.entidad
                END
            AND ISNULL(p.detalle, '') = ISNULL(
                CASE 
                    WHEN LOWER(t.entidad) LIKE '%serv. limpieza%' THEN t.entidad
                    ELSE t.detalle
                END, ''
            )
            AND p.nombre_consorcio = t.nombre_consorcio
    );

	--elimino la tabla temporal
	DROP TABLE #temp_proveedores
END
GO

/* --- IMPORTA INQUILINOS Y PROPIETARIOS (Inquilino-propietarios-datos.csv) --- */
CREATE OR ALTER PROCEDURE personas.sp_importar_inquilinos_propietarios
    @ruta_archivo VARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '--- Iniciando importación ---';

    -- Se verifica si la tabla temporal existe
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

    -- Se carga el CSV con BULK INSERT
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

    -- Eliminar duplicados en el la tabla temporal segun dni
    ;WITH cte AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY DNI ORDER BY DNI) AS rn
        FROM ##InquilinosTemp_global
        )
    DELETE FROM cte WHERE rn > 1;

    -- Insertar en tabla persona sin duplicar
    INSERT INTO personas.persona (nro_documento, tipo_documento, nombre, mail, telefono, cbu)
    SELECT
            DNI,
            'DNI' as tipo_documento,
            TRIM(UPPER(CONCAT(
                ISNULL(nombre, ''), 
                CASE WHEN nombre IS NOT NULL AND apellido IS NOT NULL THEN ' ' ELSE '' END,
                ISNULL(apellido, '')
            ))) AS nombre,
            REPLACE(TRIM(LOWER(EmailPersonal)), ' ', '') AS mail,
            TelefonoContacto AS telefono,
            CVU_CBU AS cbu
        FROM ##InquilinosTemp_global
    WHERE DNI IS NOT NULL
    AND NOT EXISTS ( 
    -- Controlamos que no exista una persona con el mismo dni y tipo en la tabla (control de insercion de duplicados)
        SELECT 1
        FROM personas.persona p
        WHERE p.nro_documento = DNI
    );

    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + 'personas fueron importadas.';
    
    PRINT 'Personas insertadas (sin duplicados).';
    PRINT '--- Importación finalizada correctamente ---';
END;
GO

/* --- IMPORTA PAGOS (Pagos_consorcios.csv) --- */
CREATE OR ALTER PROCEDURE finanzas.sp_importar_pagos
    @ruta_archivo NVARCHAR(4000)
AS
BEGIN
    -- Ya que los pagos tienen varias claves foraneas, no hacemos la insercion en la tabla final aca sino que lo hacemos
    -- en el sp relacionar_pagos donde ya disponemos de todos los datos para dichas claves
    
    SET NOCOUNT ON;
    PRINT '---- Inicia la importacion archivo de pagos ----';
    
    IF OBJECT_ID('tempdb..##temp_pagos') IS NOT NULL
        DROP TABLE ##temp_pagos;

    CREATE TABLE ##temp_pagos(
        id_pago INT,
        fecha DATE,
        cbu VARCHAR(50),
        valor VARCHAR(100)
    );

    SET DATEFORMAT dmy;
    DECLARE @ruta_esc NVARCHAR(4000) = REPLACE(@ruta_archivo, '''', '''''');
    DECLARE @sql NVARCHAR(MAX);
    
    SET @sql = N'
        BULK INSERT ##temp_pagos
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
        DROP TABLE IF EXISTS ##temp_pagos;
        RETURN;
    END CATCH;

    -- Se eliminan registros con informacion incompleta
    DELETE FROM ##temp_pagos
    WHERE fecha IS NULL OR valor IS NULL OR id_pago IS NULL;

    PRINT 'Datos de pagos cargados en tabla temporal ##temp_pagos.';
    PRINT '---- Finaliza la importacion del archivo de pagos ----';
END;
GO

/* --- IMPORTA SERVICIOS (Servicios.servicios.json) --- */
CREATE OR ALTER PROCEDURE finanzas.sp_importar_servicios
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

    -- Normalizar valores
    UPDATE #tempConsorcios
    SET
        mes = utils.fn_limpiar_espacios(mes),
        bancarios = utils.fn_normalizar_monto(bancarios),
        limpieza = utils.fn_normalizar_monto(limpieza),
        administracion = utils.fn_normalizar_monto(administracion),
        seguros = utils.fn_normalizar_monto(seguros),
        gastos_generales = utils.fn_normalizar_monto(gastos_generales),
        servicios_agua = utils.fn_normalizar_monto(servicios_agua),
        servicios_luz = utils.fn_normalizar_monto(servicios_luz),
        servicios_internet = utils.fn_normalizar_monto(servicios_internet);

    -- Insertar tipos de gasto (si no existen)
    INSERT INTO finanzas.tipo_gasto (detalle)
    SELECT detalle
    FROM (VALUES ('BANCARIOS'), ('LIMPIEZA'), ('ADMINISTRACION'), ('SEGUROS'),
           ('GASTOS GENERALES'), ('SERVICIOS PUBLICOS-Agua'), 
           ('SERVICIOS PUBLICOS-Luz'), ('SERVICIOS PUBLICOS-Internet')
    ) AS t(detalle)
    WHERE NOT EXISTS (
        SELECT 1 FROM finanzas.tipo_gasto g WHERE g.detalle = t.detalle
    );

    -- Insertar expensas por consorcio/mes
    INSERT INTO finanzas.expensa (id_consorcio, fecha_emision)
    SELECT DISTINCT c.id_consorcio,
        TRY_CONVERT(DATE, CONCAT('01-', m.mes_num, '-', @Anio), 105)
    FROM #tempConsorcios tc
    INNER JOIN consorcios.consorcio c ON c.nombre = tc.nombre_consorcio
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
        SELECT 1 FROM finanzas.expensa e
        WHERE e.id_consorcio = c.id_consorcio
          AND e.fecha_emision = TRY_CONVERT(DATE, CONCAT('01-', m.mes_num, '-', @Anio), 105)
    );

    -- Insertar gastos ordinarios (si no existen)
    INSERT INTO finanzas.gasto_ordinario (id_expensa, id_tipo_gasto, detalle, nro_factura, importe)
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
    INNER JOIN consorcios.consorcio c ON c.nombre = tc.nombre_consorcio
    CROSS APPLY (
        SELECT CASE LOWER(LTRIM(RTRIM(tc.mes)))
            WHEN 'enero' THEN '01' WHEN 'febrero' THEN '02' WHEN 'marzo' THEN '03'
            WHEN 'abril' THEN '04' WHEN 'mayo' THEN '05' WHEN 'junio' THEN '06'
            WHEN 'julio' THEN '07' WHEN 'agosto' THEN '08' WHEN 'septiembre' THEN '09'
            WHEN 'octubre' THEN '10' WHEN 'noviembre' THEN '11' WHEN 'diciembre' THEN '12'
            ELSE NULL
        END AS mes_num
    ) AS m
    INNER JOIN finanzas.expensa e ON e.id_consorcio = c.id_consorcio
        AND e.fecha_emision = TRY_CONVERT(DATE, CONCAT('01-', m.mes_num, '-', @Anio), 105)
    CROSS JOIN finanzas.tipo_gasto t
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
        SELECT 1 FROM finanzas.gasto_ordinario gaor
        WHERE gaor.id_expensa = e.id_expensa
          AND gaor.id_tipo_gasto = t.id_tipo_gasto
    );

    
    PRINT '--- Proceso de importacion de servicios finalizado ---';
    DROP TABLE IF EXISTS #tempConsorcios;
END
GO

/* --- IMPORTA UNIDADES FUNCIONALES (UF por consorcios.txt) --- */
CREATE OR ALTER PROCEDURE consorcios.sp_importar_uf_por_consorcios
    @ruta_archivo NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    -- Si la tabla temporal ya existe, se elimina para evitar importar datos desconocidos
    IF OBJECT_ID('tempdb..#temp_UF') IS NOT NULL
        DROP TABLE #temp_UF;

    -- Se crea la tabla temporal
    CREATE TABLE #temp_UF
    (
        nom_consorcio VARCHAR(255),
        num_UF INT,
        piso VARCHAR (50),
        departamento CHAR (10),
        coeficiente VARCHAR(50),
        m2_UF INT,
        baulera CHAR(4),
        cochera CHAR(4),
        m2_baulera INT,
        m2_cochera INT
    );

    PRINT '--- Iniciando importacion de unidades funcionales por consorcio ---';

    -- Se limpia la ruta
    DECLARE @ruta_esc NVARCHAR(4000) = REPLACE(@ruta_archivo, '''', '''''');
    DECLARE @sql NVARCHAR(MAX);
    -- Se importa el archivo de texto con bulk insert
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

    -- Se importan las unidades funcionales en la tabla final
    INSERT INTO consorcios.unidad_funcional (
        id_unidad_funcional, id_consorcio, metros_cuadrados, piso, departamento, cochera, baulera, coeficiente
    )
    SELECT
        t.num_UF,
        c.id_consorcio,
        -- Se calculan los m2 totales sumando m2 de la UF, m2 de la baulera y m2 de la cochera
        COALESCE(t.m2_UF,0) + COALESCE(t.m2_baulera,0) + COALESCE(t.m2_cochera,0),
        t.piso,
        t.departamento,
        -- Se indica si tiene o no cochera y baulera
        CASE WHEN UPPER(LTRIM(RTRIM(t.cochera))) IN ('SI','SÍ','1','TRUE') THEN 1 ELSE 0 END,
        CASE WHEN UPPER(LTRIM(RTRIM(t.baulera))) IN ('SI','SÍ','1','TRUE') THEN 1 ELSE 0 END,
        TRY_CAST(REPLACE(ISNULL(t.coeficiente,'0'), ',', '.') AS DECIMAL(6,3))
    FROM #temp_UF AS t
    -- Se realiza junta con la tabla de consorcios utilizando el campo de nombre
    INNER JOIN consorcios.consorcio AS c
        ON LTRIM(RTRIM(UPPER(c.nombre))) = LTRIM(RTRIM(UPPER(t.nom_consorcio)))
    -- Se verifica que no existe aun una unidad funcional que tenga el mismo ID y pertenezca al mismo consorcios. (Control de insercion de duplicados)
    WHERE NOT EXISTS (
        SELECT 1 FROM consorcios.unidad_funcional uf
        WHERE uf.id_consorcio = c.id_consorcio
          AND uf.id_unidad_funcional = t.num_UF
    );

    PRINT 'Datos insertados en la tabla final.';
    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + 'unidades funcionales fueron importadas.';
    PRINT '--- Proceso  importacion de unidades funcionales por consorcio finalizado ---';

    DROP TABLE IF EXISTS #temp_UF;
END
GO

/* --- RELACIONA INQUILINOS CON UNIDADES FUNCIONALES (Inquilino-propietarios-UF.csv) --- */
CREATE OR ALTER PROCEDURE personas.sp_relacionar_inquilinos_uf
    @ruta_archivo VARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '--- Iniciando importación de datos de inquilino - UF ---';

    --- Se crea la tabla temporal global para staging
    IF OBJECT_ID('tempdb..##InquilinosUFTemp') IS NOT NULL 
        DROP TABLE ##InquilinosUFTemp;
    CREATE TABLE ##InquilinosUFTemp (
        CVU_CBU VARCHAR(23),
        nombre_consorcio VARCHAR(80),
        id_unidad_funcional INT,
        piso CHAR(2),
        depto CHAR(2)
    );

    PRINT 'Tabla temporal ##InquilinosUFTemp creada.';

    -- Se importa el CSV con BULK INSERT
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        BULK INSERT ##InquilinosUFTemp
        FROM ''' + @ruta_archivo + N'''
        WITH (
            FIELDTERMINATOR = ''|'',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2,
            TABLOCK
        );
    ';

    EXEC sp_executesql @sql;


    -- Se realiza limpieza de datos
    UPDATE ##InquilinosUFTemp
    SET depto = RTRIM(REPLACE(REPLACE(depto, CHAR(13), ''), CHAR(10), ''));


    -- Se eliminan datos duplicados que puedan provenir del archivo
    ;WITH D AS (
        SELECT *,
               ROW_NUMBER() OVER (
                        PARTITION BY CVU_CBU, nombre_consorcio, id_unidad_funcional
                        ORDER BY (SELECT NULL)
                    ) as rn
        FROM ##InquilinosUFTemp
    )
    DELETE FROM D WHERE rn > 1;


    -- Se insertan las personas en la tabla de roles
    INSERT INTO personas.rol
        (id_unidad_funcional, id_consorcio, nombre_rol, nro_documento, 
         tipo_documento, activo, fecha_inicio)
    SELECT
        uf.id_unidad_funcional,
        c.id_consorcio,
        CASE WHEN g.Inquilino = 1 THEN 'inquilino' ELSE 'propietario' END,
        p.nro_documento,
        p.tipo_documento,
        1,
        GETDATE()
    FROM ##InquilinosUFTemp iuf
    JOIN ##InquilinosTemp_global g ON g.CVU_CBU = iuf.CVU_CBU -- Se asocia la persona con la uf segun el CBU
    JOIN personas.persona p ON p.nro_documento = g.DNI 
    JOIN consorcios.consorcio c ON c.nombre = iuf.nombre_consorcio -- Se busca el id de consorcio segun el nombre
    JOIN consorcios.unidad_funcional uf 
         ON uf.id_consorcio = c.id_consorcio
        AND uf.id_unidad_funcional = iuf.id_unidad_funcional
    WHERE NOT EXISTS ( -- Se verifica que no exista aun un rol que tenga la misma uf, documento, tipo, mismo rol y que este activo.
        SELECT 1
        FROM personas.rol r
        WHERE r.id_unidad_funcional = uf.id_unidad_funcional
          AND r.nro_documento = p.nro_documento
          AND r.tipo_documento = p.tipo_documento
          AND r.nombre_rol = CASE WHEN g.Inquilino = 1 THEN 'inquilino' ELSE 'propietario' END
          AND r.activo = 1
    );

    PRINT '--- Proceso de relación Inquilino-UF finalizado ---';
END;
GO

/* --- RELACIONA PAGOS CON UNIDAD FUNCIONAL --- */
CREATE OR ALTER PROCEDURE finanzas.sp_relacionar_pagos
AS
BEGIN
    SET NOCOUNT ON;
    -- Este SP se relaciona con la tabla de consorcio, uf y pagos
    PRINT '--- Iniciando la asociacion e INSERCION de pagos... ---';

    -- Se eliminan los registros duplicados en la tabla de pagos
    ;WITH C AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY id_pago  ORDER BY (SELECT NULL)) AS rn
        FROM ##temp_pagos
    )
    DELETE FROM C WHERE rn > 1;

    -- Se insertan los pagos utilizando los datos de las tablas temporales ##temp_pagos y ##InquilinosUFTemp (STAGING) 
    INSERT INTO finanzas.pago (id_pago, fecha_pago, monto, 
                            cbu_origen, estado, id_unidad_funcional,   
                            id_consorcio, id_expensa)
    SELECT 
        tp.id_pago,
        tp.fecha,
        utils.fn_normalizar_monto(valor) AS monto, 
        tp.cbu, 
        'asociado',
        uf.id_unidad_funcional, 
        c.id_consorcio,
        UltimaExpensa.id_expensa 
    FROM ##temp_pagos AS tp
    INNER JOIN ##InquilinosUFTemp AS iuf ON tp.cbu = iuf.CVU_CBU -- Se busca la fila donde coincida CBU de inquilino en (##InquilinosUFTemp) con cbu del pago
    INNER JOIN consorcios.consorcio AS c ON c.nombre = iuf.nombre_consorcio -- Se busca el consorcio al que pertenece la UF del pago
    INNER JOIN consorcios.unidad_funcional AS uf ON uf.id_consorcio = c.id_consorcio AND uf.departamento = iuf.depto and uf.piso = iuf.piso
    CROSS APPLY (
        -- Busca la expensa más reciente PARA ESE CONSORCIO que se haya emitido ANTES O EL MISMO DÍA del pago.
        SELECT TOP 1 e.id_expensa
        FROM finanzas.expensa AS e
        WHERE e.id_consorcio = c.id_consorcio AND e.fecha_emision <= tp.fecha
        ORDER BY e.fecha_emision DESC
    ) AS UltimaExpensa
    -- Control de insercion de duplicados. No puede existir ya en la tabla un registro con el mismo id. 
    WHERE NOT EXISTS (
        SELECT 1 FROM finanzas.pago p WHERE p.id_pago = tp.id_pago
    );
END
GO

/* ---  GENERA PRORRATEO --- */
CREATE OR ALTER PROCEDURE consorcios.sp_actualizar_prorrateo
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '---- Iniciando calculo de prorrateo por unidad funcional ----';

    UPDATE uf
    SET uf.prorrateo = ROUND((CAST(uf.metros_cuadrados AS decimal(12,3)) / tot.total_m2) * 100, 2)
    FROM consorcios.unidad_funcional AS uf
    INNER JOIN (
        SELECT id_consorcio, SUM(metros_cuadrados) AS total_m2
        FROM consorcios.unidad_funcional
        GROUP BY id_consorcio
    ) AS tot
        ON uf.id_consorcio = tot.id_consorcio;

    PRINT 'Se calculo el prorrateo de' + CAST(@@ROWCOUNT AS VARCHAR(10)) + 'unidades funcionales.';
    PRINT '---- Finaliza calculo de prorrateo por unidad funcional ----';
END
GO

create or alter procedure consorcios.sp_actualizar_cbu_uf
as
begin
    PRINT 'Actualizando CBU en unidad_funcional...';

    UPDATE uf
    SET uf.cbu = itg.CVU_CBU
    FROM consorcios.unidad_funcional uf
    INNER JOIN ##InquilinosUFTemp iuf ON uf.id_consorcio = uf.id_consorcio AND uf.departamento = iuf.depto  AND uf.piso = iuf.piso
    INNER JOIN ##InquilinosTemp_global itg on itg.CVU_CBU = iuf.CVU_CBU

    PRINT CAST(@@ROWCOUNT AS VARCHAR(10))  + ' unidades funcionales actualizadas con CBU.';
end
go

/* --- EJECUTA TODOS LOS SP PARA IMPORTAR ARCHIVOS --- */
create or alter procedure utils.sp_importar_archivos
as
begin	
	exec consorcios.sp_importar_consorcios @ruta_archivo = 'C:\Archivos para el tp\datos varios.xlsx'
	exec personas.sp_importar_proveedores @ruta_archivo ='C:\Archivos para el tp\datos varios.xlsx' 
	exec finanzas.sp_importar_pagos @ruta_archivo = 'C:\Archivos para el tp\pagos_consorcios.csv'
	exec consorcios.sp_importar_uf_por_consorcios @ruta_archivo = 'C:\Archivos para el tp\UF por consorcio.txt' 
	exec personas.sp_importar_inquilinos_propietarios @ruta_archivo = 'C:\Archivos para el tp\Inquilino-propietarios-datos.csv'
	exec finanzas.sp_importar_servicios @ruta_archivo = 'C:\Archivos para el tp\Servicios.Servicios.json', @anio=2025
    exec personas.sp_relacionar_inquilinos_uf @ruta_archivo = 'C:\Archivos para el tp\Inquilino-propietarios-UF.csv'
    exec consorcios.sp_actualizar_cbu_uf
	exec finanzas.sp_relacionar_pagos
	exec consorcios.sp_actualizar_prorrateo
end
go
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DE CREACION DE PROCEDIMIENTOS PARA IMPORTAR ARCHIVOS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CREACION DE PROCEDIMIENTOS PARA GENERAR REPORTES  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
-------------------------------------------------------------------------------------------------
/* ---
    Reporte 1.
        Flujo de caja semanal:
            - Total recaudado por semana
            - Promedio en el periodo
            - Acumulado progresivo
--- */
CREATE OR ALTER PROCEDURE datos.sp_reporte_1
    @id_consorcio INT = NULL, 
    @anio_desde INT = NULL,   
    @anio_hasta INT = NULL
WITH EXECUTE AS owner
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @where NVARCHAR(MAX) = N' WHERE 1=1 ';

    -- Se contruyen filtros dinamicos concatenando a la cadena del where según si el parámetro fue pasado al sp o no.
    IF @id_consorcio IS NOT NULL
        SET @where += N' AND e.id_consorcio = @id_consorcio ';

    IF @anio_desde IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) >= @anio_desde ';

    IF @anio_hasta IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) <= @anio_hasta ';

    --- Se utiliza SQL dinámico para la utilización del where con la lógica de concatenación. 
    SET @sql = N'
        WITH Pagos AS (
            SELECT
                p.id_pago, p.monto, p.fecha_pago,
                YEAR(p.fecha_pago) AS anio, DATEPART(WEEK, p.fecha_pago) AS semana
            FROM finanzas.pago p
            LEFT JOIN finanzas.expensa e ON e.id_expensa = p.id_expensa
            ' + @where + N'
        ),
        TotalSemanal AS (
            SELECT anio, semana,
                SUM(monto) AS total_semanal
            FROM Pagos 
            GROUP BY anio, semana
        )
        SELECT 
            anio, semana, total_semanal,
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
CREATE OR ALTER PROCEDURE datos.sp_reporte_2
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

    -- Se construyen filtros dinamicos concatenando a la cadena del where según si el parámetro fue pasado al sp o no.
     IF @anio IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) = @anio ';
    IF @min IS NOT NULL AND @max IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) BETWEEN @min AND @max ';
    ELSE IF @min IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) >= @min ';
    ELSE IF @max IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) <= @max ';

    -- Se limpian los datos de departamento y se obtienen las columnas del PIVOT
    SELECT 
        @cols = STRING_AGG(
                    QUOTENAME(REPLACE(LTRIM(RTRIM(departamento)), ' ', '_')),
                    ','
                 )
    FROM (
        SELECT DISTINCT departamento
        FROM consorcios.unidad_funcional
    ) AS d;

    -- Se construye el SQL dinamico con los filtros generados previamente
    SET @sql = N'
        WITH mes_uf_CTE AS (
            SELECT 
                FORMAT(p.fecha_pago, ''yyyy-MM'') AS mes, 
                REPLACE(LTRIM(RTRIM(uf.departamento)), '' '', ''_'') AS departamento,
                SUM(p.monto) AS total_monto
            FROM finanzas.pago p
            JOIN consorcios.unidad_funcional uf  
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

CREATE OR ALTER PROCEDURE datos.sp_reporte_3
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
        FROM finanzas.expensa e
        INNER JOIN finanzas.gasto_ordinario gaor 
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
        FROM finanzas.expensa e
        INNER JOIN finanzas.gasto_extraordinario ge 
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

-------------------------------------------------------------------------------------------------
/*
    Reporte 4. 
        Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos. 
*/
CREATE OR ALTER PROCEDURE datos.sp_reporte_4
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
        FROM finanzas.gasto_ordinario gor
        INNER JOIN finanzas.expensa e ON gor.id_expensa = e.id_expensa
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
        FROM finanzas.gasto_extraordinario ge
        INNER JOIN finanzas.expensa e ON ge.id_expensa = e.id_expensa
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
        FROM finanzas.pago p
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
    Reporte 5:
        Obtenga los 3 (tres) propietarios con mayor morosidad. Presente información de contacto y
        DNI de los propietarios para que la administración los pueda contactar o remitir el trámite al
        estudio jurídico.
*/
CREATE OR ALTER PROCEDURE datos.sp_reporte_5
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
    FROM personas.persona p
    INNER JOIN personas.rol r
        ON p.nro_documento = r.nro_documento
        AND p.tipo_documento = r.tipo_documento
        AND r.nombre_rol = 'Propietario'
    INNER JOIN consorcios.unidad_funcional uf
        ON r.id_unidad_funcional = uf.id_unidad_funcional
        AND r.id_consorcio = uf.id_consorcio
    INNER JOIN finanzas.detalle_expensas_por_uf depuf
        ON uf.id_unidad_funcional = depuf.id_unidad_funcional
        AND uf.id_consorcio = depuf.id_consorcio
    INNER JOIN finanzas.expensa e
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
    Reporte 6
        Muestre las fechas de pagos de expensas ordinarias de cada UF y la cantidad de días que
        pasan entre un pago y el siguiente, para el conjunto examinado.

*/

CREATE OR ALTER PROCEDURE datos.sp_reporte_6
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
        FROM finanzas.pago p
        INNER JOIN finanzas.expensa e ON p.id_expensa = e.id_expensa
        INNER JOIN finanzas.gasto_ordinario go ON e.id_expensa = go.id_expensa
        INNER JOIN consorcios.unidad_funcional uf ON p.id_unidad_funcional = uf.id_unidad_funcional
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
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DE LA CREACION DE PROCEDIMIENTOS PARA GENERAR REPORTES  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CREACION DE PROCEDIMIENTOS PARA GENERAR DATOS ADICIONALES  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/* --- GENERA CUOTAS CORRESPONDIENTES A GASTOS EXTRAORDINARIOS ---*/
CREATE OR ALTER PROCEDURE utils.sp_generar_cuotas
AS
BEGIN
    INSERT INTO finanzas.cuota (nro_cuota, id_gasto_extraordinario)
    SELECT 
        n.nro,
        ge.id_gasto_extraordinario
    FROM finanzas.gasto_extraordinario ge
    CROSS APPLY (
        SELECT TOP (ge.total_cuotas) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS nro
        FROM sys.all_objects
    ) n
    WHERE NOT EXISTS (
        SELECT 1 FROM finanzas.cuota c
        WHERE c.id_gasto_extraordinario = ge.id_gasto_extraordinario
          AND c.nro_cuota = n.nro
    );
END
GO

/* --- Generar Envíos de Expensas Random ---*/
CREATE OR ALTER PROCEDURE utils.sp_generar_envios_expensas
    @cantidad_registros INT 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @i INT = 1;
    DECLARE @id_expensa INT;
    DECLARE @id_uf INT;
    DECLARE @IdConsorcio INT;
    DECLARE @IdTipo INT;
    DECLARE @TipoDoc VARCHAR(10);
    DECLARE @Documento BIGINT;
    DECLARE @FechaEnvio DATE;
    
    WHILE @i <= @cantidad_registros
    BEGIN
        -- Seleccionar IDs random de tablas relacionadas
        SET @id_expensa = (SELECT TOP 1 id_expensa FROM finanzas.expensa ORDER BY NEWID());
        SET @IdTipo = (SELECT TOP 1 id_tipo_envio FROM gestion.tipo_envio ORDER BY NEWID());
        SELECT TOP 1 
			  @id_uf = id_unidad_funcional,
			  @IdConsorcio = id_consorcio
	   FROM consorcios.unidad_funcional 
       ORDER BY NEWID();
        
        -- Obtener un documento random de la tabla persona
        SELECT TOP 1 
            @TipoDoc = tipo_documento,
            @Documento = nro_documento
        FROM personas.persona
        ORDER BY NEWID();
        
        -- Generar fecha random en los últimos 365 días
        SET @FechaEnvio = DATEADD(DAY, -FLOOR(RAND() * 365), GETDATE());
        
        INSERT INTO gestion.envio_expensa (
            id_expensa, 
            id_unidad_funcional, 
            id_consorcio,
            id_tipo_envio, 
            destinatario_nro_documento, 
            destinatario_tipo_documento, 
            fecha_envio
        )
        VALUES (
            @id_expensa, 
            @id_uf, 
            @IdConsorcio,
            @IdTipo, 
            @Documento, 
            @TipoDoc, 
            @FechaEnvio
        );
        
        SET @i = @i + 1;
    END
    
    PRINT 'Se generaron ' + CAST(@cantidad_registros AS VARCHAR) + ' envíos de expensas random.';
END
GO

/*--- GENERA GASTOS EXTRAORDINARIOS RELACIONADOS A EXPENSA ---*/
CREATE OR ALTER PROCEDURE utils.sp_generar_gastos_extraordinarios
    @cantidad_registros INT 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @i INT = 1;
    DECLARE @id_expensa INT;
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
    
    WHILE @i <= @cantidad_registros
    BEGIN
        SET @id_expensa = (SELECT TOP 1 id_expensa FROM finanzas.expensa ORDER BY NEWID());
        SET @Detalle = (SELECT TOP 1 Descripcion FROM @Detalles ORDER BY NEWID());
        SET @PagoEnCuotas = CASE WHEN RAND() > 0.5 THEN 1 ELSE 0 END;
        SET @TotalCuotas = CASE WHEN @PagoEnCuotas = 1 THEN FLOOR(RAND() * 11) + 2 ELSE 1 END;
        SET @ImporteTotal = ROUND(RAND() * 500000 + 50000, 2);
        
        INSERT INTO finanzas.gasto_extraordinario (id_expensa, detalle, total_cuotas, 
                                           pago_en_cuotas, importe_total)
        VALUES (@id_expensa, @Detalle, @TotalCuotas, @PagoEnCuotas, @ImporteTotal);
        
        SET @i = @i + 1;
    END
    
    PRINT 'Se generaron ' + CAST(@cantidad_registros AS VARCHAR) + ' gastos extraordinarios random.';
END
GO

/*--- GENERA PAGOS ---*/
CREATE OR ALTER PROCEDURE utils.sp_generar_pagos
    @cantidad_registros INT 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @i INT = 1;
    DECLARE @IdPago INT;
    DECLARE @id_uf INT;
    DECLARE @IdConsorcio INT;
    DECLARE @id_expensa INT;
    DECLARE @Fecha DATE;
    DECLARE @Monto DECIMAL(18,2);
    DECLARE @CbuOrigen VARCHAR(22);
    DECLARE @Estado VARCHAR(20);
    
    -- Obtener el último id_pago existente
    SELECT @IdPago = ISNULL(MAX(id_pago), 0) FROM finanzas.pago;
    
    WHILE @i <= @cantidad_registros
    BEGIN
        SET @IdPago = @IdPago + 1;
        
        -- Seleccionar unidad funcional y consorcio juntos
        SELECT TOP 1 
            @id_uf = id_unidad_funcional,
            @IdConsorcio = id_consorcio
        FROM consorcios.unidad_funcional 
        ORDER BY NEWID();
        
        -- Seleccionar una expensa asociada al mismo consorcio
        SET @id_expensa = (
            SELECT TOP 1 id_expensa 
            FROM finanzas.expensa 
            WHERE id_consorcio = @IdConsorcio
            ORDER BY NEWID()
        );

        -- Si no se encontró expensa, elegir cualquiera 
        IF @id_expensa IS NULL
            SET @id_expensa = (SELECT TOP 1 id_expensa FROM finanzas.expensa ORDER BY NEWID());

        SET @Fecha = DATEADD(DAY, -FLOOR(RAND() * 180), GETDATE());
        SET @Monto = ROUND(RAND() * 100000 + 5000, 2);
        
        SET @CbuOrigen = (SELECT TOP 1 cbu FROM personas.persona WHERE cbu IS NOT NULL ORDER BY NEWID());
        
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
        
        INSERT INTO finanzas.pago (
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
            @id_uf,
            @IdConsorcio,
            @id_expensa,
            @Fecha,
            @Monto,
            @CbuOrigen,
            @Estado
        );
        
        SET @i = @i + 1;
    END
    
    PRINT 'Se generaron ' + CAST(@cantidad_registros AS VARCHAR) + ' pagos random.';
END
GO

/*--- GENERA LOS TIPOS DE ENVIO---*/
CREATE OR ALTER PROCEDURE utils.sp_generar_tipos_envio_random
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Limpiar tabla si existe datos
    IF EXISTS (SELECT 1 FROM gestion.tipo_envio)
    BEGIN
        PRINT 'La tabla tipo_envio ya contiene datos. No se insertarán duplicados.';
        RETURN;
    END
    
    INSERT INTO gestion.tipo_envio (detalle) VALUES
        ('Email'),
        ('WhatsApp');
    
    PRINT 'Se generaron los tipos de envío predefinidos.';
END
GO

/* --- GENERA VENCIMIENTO DE EXPENSAS ---*/
CREATE OR ALTER PROCEDURE utils.sp_generar_vencimientos_expensas
    @dias_primer_vencimiento INT ,  -- Días después de emisión para 1er vencimiento
    @cantidad_registros INT   -- Días después de emisión para 2do vencimiento
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Actualizar solo los registros que tienen fecha_emision pero no tienen vencimientos
        UPDATE finanzas.expensa
        SET 
            primer_vencimiento = DATEADD(DAY, @dias_primer_vencimiento, fecha_emision),
            segundo_vencimiento = DATEADD(DAY, @cantidad_registros, fecha_emision)
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

/*--- CALCULA DETALLES DE EXPENSA POR UNIDAD FUNCIONAL ---*/
CREATE OR ALTER PROCEDURE utils.sp_generar_detalle_expensas_por_uf
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

    DECLARE @expensas TABLE (id_expensa INT, fecha_1er_vto DATE, fecha_2do_vto DATE);
    DECLARE @UF TABLE (id_unidad_funcional INT, id_consorcio INT);
    DECLARE @gasto_ord TABLE (monto DECIMAL(12,2));
    DECLARE @gasto_ext TABLE (monto DECIMAL(12,2));

    INSERT INTO @expensas
    SELECT id_expensa, primer_vencimiento, segundo_vencimiento FROM finanzas.expensa;

    INSERT INTO @UF
    SELECT id_unidad_funcional, id_consorcio FROM consorcios.unidad_funcional;

    INSERT INTO @gasto_ord
    SELECT importe FROM finanzas.gasto_ordinario;

    INSERT INTO @gasto_ext
    SELECT importe_total FROM finanzas.gasto_extraordinario;

    IF NOT EXISTS (SELECT 1 FROM @expensas) OR NOT EXISTS (SELECT 1 FROM @UF)
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
        FROM @expensas ORDER BY NEWID();

        SELECT TOP 1 
            @id_unidad_funcional = id_unidad_funcional,
            @id_consorcio = id_consorcio
        FROM @UF ORDER BY NEWID();

        -- Buscar fecha de pago (si existe)
        SELECT TOP 1 @fecha_pago = fecha_pago
        FROM finanzas.pago
        WHERE id_expensa = @id_expensa
          AND id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio = @id_consorcio;

        IF @fecha_pago IS NULL
            SET @fecha_pago = CAST(GETDATE() AS DATE); -- sin pago: hoy

        -- Gastos ordinarios y extraordinarios
        SELECT TOP 1 @gastos_ordinarios = monto FROM @gasto_ord ORDER BY NEWID();
        SELECT TOP 1 @gastos_extraordinarios = monto FROM @gasto_ext ORDER BY NEWID();

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
        INSERT INTO finanzas.detalle_expensas_por_uf (
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
 
/*--- CALCULA LOS ESTADOS FINANCIEROS (Corresponde a UF)---*/
CREATE OR ALTER PROCEDURE utils.sp_generar_estado_financiero
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Limpiar la tabla de estados anteriores
    DELETE FROM finanzas.estado_financiero;

    -- 2. Insertar los nuevos estados financieros de forma masiva
    INSERT INTO finanzas.estado_financiero (
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

    FROM finanzas.expensa e
    LEFT JOIN (
        SELECT id_expensa, SUM(importe) AS monto FROM finanzas.gasto_ordinario GROUP BY id_expensa
    ) AS goo ON e.id_expensa = goo.id_expensa
    LEFT JOIN (
        SELECT id_expensa, SUM(importe_total) AS monto FROM finanzas.gasto_extraordinario GROUP BY id_expensa
    ) AS ge ON e.id_expensa = ge.id_expensa
    LEFT JOIN finanzas.pago AS p ON e.id_expensa = p.id_expensa
    LEFT JOIN finanzas.detalle_expensas_por_uf AS de ON e.id_expensa = de.id_expensa

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

/*--- EJECUTA TODOS LOS SP CREADOS ---*/
CREATE OR ALTER PROCEDURE utils.sp_crear_datos_adicionales
as
begin
	
	EXEC utils.sp_generar_tipos_envio_random;
	EXEC utils.sp_generar_envios_expensas @cantidad_registros = 10;
	EXEC utils.sp_generar_estado_financiero;
	EXEC utils.sp_generar_gastos_extraordinarios @cantidad_registros = 10;
	EXEC utils.sp_generar_cuotas ;
	EXEC utils.sp_generar_pagos @cantidad_registros = 10
	EXEC utils.sp_generar_vencimientos_expensas @dias_primer_vencimiento=15,@cantidad_registros=20
	EXEC utils.sp_generar_detalle_expensas_por_uf @cantidad=10

end;

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FINALIZA CREACION DE PROCEDIMIENTOS PARA GENERAR DATOS ADICIONALES  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  FIN DEL SCRIPT  <<<<<<<<<<<<<<<<<<<<<<<<<<*/