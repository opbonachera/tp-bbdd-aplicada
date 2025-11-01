
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
            Inquilino TINYINT
        );
    END
    
    PRINT 'Tabla temporal creada.';

    --2.  Cargar el CSV usando BULK INSERT
    DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            BULK INSERT #InquilinosTemp
            FROM ''' + @RutaArchivo + N'''
            WITH (
                FIELDTERMINATOR = '';'',
                ROWTERMINATOR = ''\n'',
                FIRSTROW = 2,
                TABLOCK
            );';
        EXEC(@sql);
    PRINT 'Datos importados en tabla temporal.';

    -- 3. Insertar en tabla persona

select * from ddbba.persona

    INSERT INTO ddbba.persona (nro_documento, tipo_documento, nombre, mail, telefono, cbu)
    SELECT
        DNI AS nro_documento,
        CASE 
            WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'DNI'
            ELSE 'Pasaporte'
        END AS tipo_documento,
        TRIM(UPPER(CONCAT(nombre, Apellido))) AS nombre,
        REPLACE(TRIM(LOWER(EmailPersonal)), ' ', '') AS mail,
        TelefonoContacto AS telefono,
        CVU_CBU AS cbu
    FROM #InquilinosTemp
    WHERE DNI IS NOT NULL;
 
    PRINT 'Personas insertadas.';

--     -- Insertar consorcios

--     CREATE TABLE #consorcioTemp (
--         nombre VARCHAR(255) NOT NULL,
--         metros_cuadrados INT,
--         direccion VARCHAR(255) NOT NULL,
--         --cbu VARCHAR(22) UNIQUE
--     );

--     INSERT #consorcioTemp (nombre, metros_cuadrados, direccion) VALUES ('Paul McCartney',52,'Abbey 1234'), ('Slash',22,'Road 321');

--     SELECT * FROM ddbba.consorcio

--     INSERT INTO ddbba.consorcio (nombre, metros_cuadrados, direccion, cbu)
--     SELECT
--         (SELECT TOP 1 nombre FROM #consorcioTemp ORDER BY NEWID()),
--         (SELECT TOP 1 metros_cuadrados FROM #consorcioTemp ORDER BY NEWID()),
--         (SELECT TOP 1 direccion FROM #consorcioTemp ORDER BY NEWID()),
--         (SELECT TOP 1 cbu FROM ddbba.persona ORDER BY NEWID());



--     -- 5. Insertar en unidad_funcional

--     CREATE TABLE #ufTemp (
--         metros_cuadrados INT,
--         piso INT,
--         departamento VARCHAR(10),
--         prorrateo FLOAT
--     );

--     INSERT #ufTemp (metros_cuadrados, piso, departamento, prorrateo) VALUES (21,3,'A',100.54), (22,4,'B',101.34), (23,5,'C',102.14);


--  SELECT * FROM ddbba.unidad_funcional


--     INSERT INTO ddbba.unidad_funcional (id_consorcio, metros_cuadrados, piso, departamento, cbu, prorrateo)
--     SELECT
--         (SELECT TOP 1 id_consorcio FROM ddbba.consorcio ORDER BY NEWID()),
--         (SELECT TOP 1 metros_cuadrados FROM #ufTemp ORDER BY NEWID()),
--         (SELECT TOP 1 piso FROM #ufTemp ORDER BY NEWID()),
--         (SELECT TOP 1 departamento FROM #ufTemp ORDER BY NEWID()), 
--         (SELECT TOP 1 CVU_CBU FROM #InquilinosTemp ORDER BY NEWID()), 
--         (SELECT TOP 1 prorrateo FROM #ufTemp ORDER BY NEWID());
    
--     PRINT 'Unidades funcionales insertadas.';

    SELECT * FROM ddbba.rol

    -- ==========================================================
    -- 6. Insertar en rol (relaciona persona con unidad)
    -- ==========================================================
    INSERT INTO ddbba.rol (id_unidad_funcional, nro_documento, tipo_documento, nombre_rol, activo, fecha_inicio)
    SELECT
        uf.id_unidad_funcional,
        p.nro_documento,
        p.tipo_documento,
        CASE 
            WHEN t.Inquilino = 1 THEN 'Inquilino'
            ELSE 'Propietario'
        END AS nombre_rol,
        1 AS activo,
        GETDATE() AS fecha_inicio
    FROM #InquilinosTemp t
    INNER JOIN ddbba.persona p
        ON p.nro_documento = t.DNI 
    INNER JOIN ddbba.unidad_funcional uf
        ON uf.cbu = p.cbu;  -- Relaciona CBU del CSV con el de la unidad funcional

    PRINT 'Roles insertados.';

    PRINT '--- Importación finalizada correctamente ---';
END;


EXEC ddbba.ImportarInquilinosPropietarios @RutaArchivo = '/var/opt/mssql/archivo/Inquilino-propietarios-datos.csv';
 