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

    -- Elimino el caracter invisible de la columna Departamento del archivo CSV
    UPDATE #InquilinosUFTemp
    SET Departamento = RTRIM(REPLACE(REPLACE(Departamento, CHAR(13), ''), CHAR(10), ''));

    -- SELECT * FROM #InquilinosUFTemp

    -- CBU que coinciden con el campo CBU de la tabla UF
    SELECT t.CVU_CBU FROM #InquilinosUFTemp t
    WHERE t.CVU_CBU IN (SELECT cbu FROM ddbba.unidad_funcional)
    
    
    -- CBU que NO coinciden con el campo CBU de la tabla UF
    SELECT t.CVU_CBU FROM #InquilinosUFTemp t
    WHERE t.CVU_CBU NOT IN (SELECT cbu FROM ddbba.unidad_funcional)

END;
GO


EXEC ddbba.ImportarInquilinosPropietariosUF
    @RutaArchivo = '/var/opt/mssql/archivo/Archivos_tp/Inquilino-propietarios-UF.csv'; 