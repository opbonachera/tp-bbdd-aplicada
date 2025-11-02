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
        CVU_CBU VARCHAR(50),
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

    -- ==========================================================
    -- 3. Insertar en tabla persona sin duplicar (SIN CBU)
    -- ==========================================================
    INSERT INTO ddbba.persona (nro_documento, tipo_documento, nombre, mail, telefono)
    SELECT
        DNI AS nro_documento,
        CASE 
            WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'DNI'
            ELSE 'Pasaporte'
        END AS tipo_documento,
        TRIM(UPPER(CONCAT(nombre, ' ', Apellido))) AS nombre,
        REPLACE(TRIM(LOWER(EmailPersonal)), ' ', '') AS mail,
        TelefonoContacto AS telefono
    FROM #InquilinosTemp t
    WHERE DNI IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM ddbba.persona p WHERE p.nro_documento = t.DNI
      );

    PRINT 'Personas insertadas (sin duplicados).';

    -- ==========================================================
    -- 4. Asignar una unidad funcional random única por persona
    -- ==========================================================
    ;WITH RandomUF AS (
        SELECT 
            uf.id_unidad_funcional,
            ROW_NUMBER() OVER (ORDER BY NEWID()) AS rn
        FROM ddbba.unidad_funcional uf
        WHERE uf.id_unidad_funcional NOT IN (
            SELECT DISTINCT id_unidad_funcional FROM ddbba.rol
        )
    ), -- Ordena las unidades funcionales aun no asignadas de manera random
    PersonasInsertadas AS (
        SELECT 
            p.nro_documento,
            p.tipo_documento,
            p.nombre,
            t.Inquilino,
            ROW_NUMBER() OVER (ORDER BY NEWID()) AS rn -- Ordena las personas de manera random
        FROM ddbba.persona p
        JOIN #InquilinosTemp t ON t.DNI = p.nro_documento
    )
    INSERT INTO ddbba.rol (id_unidad_funcional, nro_documento, tipo_documento, nombre_rol, activo, fecha_inicio)
    SELECT 
        uf.id_unidad_funcional,
        p.nro_documento,
        p.tipo_documento,
        CASE WHEN p.Inquilino = 1 THEN 'Inquilino' ELSE 'Propietario' END AS nombre_rol,
        1 AS activo,
        GETDATE() AS fecha_inicio
    FROM PersonasInsertadas p
    JOIN RandomUF uf ON uf.rn = p.rn; -- Junta las unidades funcionales con las personas, por ejemplo si una persona le toco el numero #1 le corresponde el #1 de uf

    PRINT 'Roles insertados y unidades funcionales asignadas.';
    
    -- ==========================================================
    -- 5. Actualizar el CBU en la unidad funcional asignada
    -- ==========================================================
    ;WITH update_cbu_cte AS (
        SELECT 
            uf.id_unidad_funcional,
            p.CVU_CBU,
            ROW_NUMBER() OVER (PARTITION BY p.CVU_CBU ORDER BY uf.id_unidad_funcional) AS rn
        FROM ddbba.unidad_funcional uf
        JOIN ddbba.rol r ON r.id_unidad_funcional = uf.id_unidad_funcional
        JOIN #InquilinosTemp p ON p.DNI = r.nro_documento
        WHERE p.CVU_CBU IS NOT NULL
    )
    UPDATE uf
    SET uf.cbu = u.CVU_CBU
    FROM ddbba.unidad_funcional uf
    JOIN update_cbu_cte u ON u.id_unidad_funcional = uf.id_unidad_funcional
    WHERE 
        u.rn = 1
        AND NOT EXISTS (
            SELECT 1 
            FROM ddbba.unidad_funcional existing_uf
            WHERE existing_uf.cbu =u.CVU_CBU
        );

    PRINT 'CBU actualizado en unidades funcionales asignadas.';

    PRINT '--- Importación finalizada correctamente ---';
END;

EXEC ddbba.importar_inquilinos_propietarios @ruta_archivo = '/app/datasets/tp/Inquilino-propietarios-datos.csv'

select * from ddbba.rol