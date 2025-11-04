
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
    -- SELECT DISTINCT nroUnidadFuncional FROM #InquilinosUFTemp
    -- SELECT  CVU_CBU FROM #InquilinosUFTemp

    PRINT 'Datos importados correctamente en #InquilinosUFTemp.';

    -- CBU que no están asignados a ninguna unidad funcional ni a ninguna persona

    -- SELECT t.CVU_CBU, t.nroUnidadFuncional, t.NombreConsorcio FROM #InquilinosUFTemp t  
    -- WHERE t.CVU_CBU NOT IN (SELECT uf.cbu FROM ddbba.unidad_funcional uf)
    -- AND t.CVU_CBU NOT IN (SELECT p.cbu FROM ddbba.persona p)

    -------------------------------------------------------------
    -- 3. Insertar persona random para los CBU nuevos
    -------------------------------------------------------------
    PRINT 'Insertando personas nuevas...';

    INSERT INTO ddbba.persona (tipo_documento, nombre, mail, telefono, cbu)
    SELECT 
        CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'DNI' ELSE 'Pasaporte' END AS tipo_documento,
        CONCAT('Persona_', RIGHT(ABS(CHECKSUM(NEWID())), 5)) AS nombre,
        CONCAT('persona', RIGHT(ABS(CHECKSUM(NEWID())), 5), '@mail.com') AS mail,
        CONCAT('+54 11 ', CAST(40000000 + (ABS(CHECKSUM(NEWID())) % 9999999) AS VARCHAR(20))) AS telefono,
        t.CVU_CBU AS cbu
    FROM #InquilinosUFTemp t
    WHERE t.CVU_CBU NOT IN (SELECT uf.cbu FROM ddbba.unidad_funcional uf)
      AND t.CVU_CBU NOT IN (SELECT p.cbu FROM ddbba.persona p);

    PRINT 'Personas nuevas insertadas.';

    -------------------------------------------------------------
    -- 4. Insertar unidades funcionales nuevas
    -------------------------------------------------------------
    PRINT 'Insertando unidades funcionales nuevas...';

    INSERT INTO ddbba.unidad_funcional (id_unidad_funcional, piso, departamento, cbu, id_consorcio)
    SELECT
        t.nroUnidadFuncional AS id_unidad_funcional,
        t.Piso,
        t.Departamento,
        t.CVU_CBU AS cbu,
        c.id_consorcio
    FROM #InquilinosUFTemp t
    INNER JOIN ddbba.consorcio c 
        ON c.nombre = t.NombreConsorcio
    WHERE t.CVU_CBU NOT IN (SELECT uf.cbu FROM ddbba.unidad_funcional uf);

    PRINT 'Unidades funcionales nuevas insertadas.';

    PRINT '--- Importación finalizada correctamente ---';
END;
GO


EXEC ddbba.ImportarInquilinosPropietariosUF
    @RutaArchivo = '/var/opt/mssql/archivo/Archivos_tp/Inquilino-propietarios-UF.csv'; 