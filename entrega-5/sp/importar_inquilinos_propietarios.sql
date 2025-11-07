use "consorcios"
go

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