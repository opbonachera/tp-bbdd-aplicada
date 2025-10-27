
CREATE OR ALTER PROCEDURE ddbba.ImportarInquilinosPropietarios
    @RutaArchivo VARCHAR(4000) 
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '--- Iniciando importación ---';

    -- ==========================================================
    -- 1. Verificar si la tabla temporal existe
    -- ==========================================================
    IF OBJECT_ID('tempdb..#InquilinosTemp') IS NULL
    BEGIN
        -- Crear tabla temporal con las columnas del CSV
        CREATE TABLE #InquilinosTemp (
            Nombre VARCHAR(100),
            Apellido VARCHAR(100),
            DNI BIGINT,
            EmailPersonal VARCHAR(150),
            TelefonoContacto VARCHAR(50),
            CVU_CBU VARCHAR(50),
            Inquilino VARCHAR(10)
        );
    END

    PRINT 'Tabla temporal creada.';

    --2.  Cargar el CSV usando BULK INSERT
    BULK INSERT #InquilinosTemp
    FROM '/var/opt/mssql/archivo/Inquilino-propietarios-datos.csv'
    WITH (
        FIELDTERMINATOR = ';',
        ROWTERMINATOR = '\n',
        FIRSTROW = 2,
        TABLOCK
    );

    PRINT 'Datos importados en tabla temporal.';

    -- Creo tablas para insertar datos de prueba

    CREATE TABLE #dniTypeTemp (
    tipo VARCHAR(15) NOT NULL
    );
    INSERT #dniTypeTemp (tipo) VALUES ('DNI'), ('PASAPORTE');


    -- 3. Insertar en tabla persona

select * from ddbba.persona

    INSERT INTO ddbba.persona (nro_documento, tipo_documento, nombre, mail, telefono)
    SELECT
        (SELECT TOP 1 DNI FROM #InquilinosTemp ORDER BY NEWID()),
        (SELECT TOP 1 tipo FROM #dniTypeTemp ORDER BY NEWID()), -- ver
        (SELECT TOP 1 CONCAT(nombre, Apellido) FROM #InquilinosTemp ORDER BY NEWID()),
        (SELECT TOP 1 EmailPersonal FROM #InquilinosTemp ORDER BY NEWID()),
        (SELECT TOP 1 TelefonoContacto FROM #InquilinosTemp ORDER BY NEWID());

    PRINT 'Personas insertadas.';

    -- Insertar consorcios

    CREATE TABLE #consorcioTemp (
        --nombre VARCHAR(255) NOT NULL,
        metros_cuadrados INT,
        direccion VARCHAR(255) NOT NULL,
        --cbu VARCHAR(22) UNIQUE
    );

    INSERT #consorcioTemp (metros_cuadrados, direccion) VALUES (52,'Abbey 1234'), (22,'Road 321');

    SELECT * FROM ddbba.consorcio

    INSERT INTO ddbba.consorcio (nombre, metros_cuadrados, direccion, cbu)
    SELECT
        (SELECT TOP 1 nombre FROM ddbba.persona ORDER BY NEWID()),
        (SELECT TOP 1 metros_cuadrados FROM #consorcioTemp ORDER BY NEWID()),
        (SELECT TOP 1 direccion FROM #consorcioTemp ORDER BY NEWID()), 
        (SELECT TOP 1 CVU_CBU FROM #InquilinosTemp ORDER BY NEWID());



    -- 5. Insertar en unidad_funcional

    CREATE TABLE #ufTemp (
        metros_cuadrados INT,
        piso INT,
        departamento VARCHAR(10),
        prorrateo FLOAT
    );

    INSERT #ufTemp (metros_cuadrados, piso, departamento, prorrateo) VALUES (21,3,'A',100.54), (22,4,'B',101.34), (23,5,'C',102.14);


    INSERT INTO ddbba.unidad_funcional (metros_cuadrados, piso, departamento, cbu, prorrateo)
    SELECT
        (SELECT TOP 1 metros_cuadrados FROM #ufTemp ORDER BY NEWID()),
        (SELECT TOP 1 piso FROM #ufTemp ORDER BY NEWID()),
        (SELECT TOP 1 departamento FROM #ufTemp ORDER BY NEWID()), 
        (SELECT TOP 1 CVU_CBU FROM #InquilinosTemp ORDER BY NEWID()), 
        (SELECT TOP 1 prorrateo FROM #ufTemp ORDER BY NEWID());

    PRINT 'Unidades funcionales insertadas.';


    -- ==========================================================
    -- 6. Insertar en rol (relaciona persona con unidad)
    -- ==========================================================

    CREATE TABLE #rolTemp (
    nombre_rol VARCHAR(50) NOT NULL CHECK (nombre_rol IN ('Propietario', 'Inquilino'))
    );

    INSERT #rolTemp (nombre_rol) VALUES ('Propietario'), ('Inquilino');


    INSERT INTO ddbba.rol (nro_documento, tipo_documento, nombre_rol, fecha_inicio)
    SELECT
        (SELECT TOP 1 DNI FROM #InquilinosTemp ORDER BY NEWID()),
        (SELECT TOP 1 tipo FROM #dniTypeTemp ORDER BY NEWID()), 
        (SELECT TOP 1 nombre_rol FROM #rolTemp ORDER BY NEWID()),
        (SELECT TOP 1 GETDATE() FROM #rolTemp ORDER BY NEWID());

    PRINT 'Roles insertados.';

END;

 