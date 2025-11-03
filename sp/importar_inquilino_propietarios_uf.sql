CREATE OR ALTER PROCEDURE ddbba.ImportarInquilinosPropietariosUF
    @RutaArchivo VARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '--- Iniciando importación de unidades funcionales ---';

    -- 1. Crear tabla temporal
    IF OBJECT_ID('tempdb..#InquilinosUFTemp') IS NOT NULL
        DROP TABLE #InquilinosUFTemp;

    CREATE TABLE #InquilinosUFTemp (
        CVU_CBU VARCHAR(25),
        NombreConsorcio VARCHAR(255),
        nroUnidadFuncional INT,
        Piso VARCHAR(10),
        Departamento VARCHAR(10)
    );

    PRINT 'Tabla temporal #InquilinosUFTemp creada.';

    -- 2. Cargar datos desde el CSV usando BULK INSERT
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        BULK INSERT #InquilinosUFTemp
        FROM ''' + @RutaArchivo + N'''
        WITH (
            FIELDTERMINATOR = ''|'',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2,
            TABLOCK
        );
    ';

    EXEC sp_executesql @sql;

    PRINT 'Datos importados correctamente en #InquilinosUFTemp.';

    -- Relacionar CBU con CBU de la tabla persona, ID de Unidad funcional y los nombres de consorcios --

    ;WITH rel_cbu AS (
        SELECT p.cbu FROM ddbba.persona p
        WHERE p.cbu NOT IN (SELECT CVU_CBU FROM #InquilinosUFTemp) 
    ),
    rel_unidad_funcional AS (
        SELECT uf.id_unidad_funcional FROM ddbba.unidad_funcional uf
        WHERE uf.id_unidad_funcional NOT IN (SELECT nroUnidadFuncional FROM #InquilinosUFTemp)
    )
    
    -- Inserto los CBU que estén en el archivo y que no estén en la tabla persona, creando datos ficticios

    INSERT INTO ddbba.persona (nro_documento, tipo_documento, nombre, mail, telefono, cbu)
    SELECT 
        ABS(CHECKSUM(NEWID())) % 90000000 + 10000000 AS nro_documento, -- DNI sintético
        'DNI' AS tipo_documento,
        CONCAT('Robert', ROW_NUMBER() OVER (ORDER BY i.CVU_CBU)) AS nombre, -- nombre ficticio
        CONCAT('Plant', ROW_NUMBER() OVER (ORDER BY i.CVU_CBU), '@ejemplo.com') AS mail,
        CONCAT('11', RIGHT(ABS(CHECKSUM(NEWID())), 8)) AS telefono, -- número genérico
        i.CVU_CBU AS cbu
    FROM #InquilinosUFTemp i
    INNER JOIN rel_cbu r ON r.cbu = i.CVU_CBU;


    -- UNIDAD FUNCIONAL
    -- UNIDAD FUNCIONAL
    -- UNIDAD FUNCIONAL
    -- UNIDAD FUNCIONAL

    --
    --
    --
    --
    --
    PRINT '--- Importación finalizada correctamente ---';
END;
GO


EXEC ddbba.ImportarInquilinosPropietariosUF
    @RutaArchivo = '/var/opt/mssql/archivo/Inquilino-propietarios-UF.csv';
