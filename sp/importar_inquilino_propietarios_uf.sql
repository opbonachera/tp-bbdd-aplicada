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
    -- Relacionar CBU con CBU de la tabla persona, ID de Unidad funcional y los nombres de consorcios --
    -- Relacionar CBU con CBU de la tabla persona, ID de Unidad funcional y los nombres de consorcios --
    -- Relacionar CBU con CBU de la tabla persona, ID de Unidad funcional y los nombres de consorcios --
    -- Relacionar CBU con CBU de la tabla persona, ID de Unidad funcional y los nombres de consorcios --
    -- Relacionar CBU con CBU de la tabla persona, ID de Unidad funcional y los nombres de consorcios --
    -- Relacionar CBU con CBU de la tabla persona, ID de Unidad funcional y los nombres de consorcios --

    PRINT '--- Importación finalizada correctamente ---';
END;
GO


EXEC ddbba.ImportarInquilinosPropietariosUF
    @RutaArchivo = '/var/opt/mssql/archivo/Inquilino-propietarios-UF.csv';
