USE consorcios;
GO

CREATE OR ALTER PROCEDURE ddbba.sp_importar_consorcios_csv
    @ruta_archivo VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Creación de la tabla temporal (debe coincidir con el CSV de 5 columnas)
    CREATE TABLE #temp_consorcios
     (
        consorcio VARCHAR(12),
        nombre VARCHAR(50),
        domicilio VARCHAR(50),
        cant_UF SMALLINT,
        M2_totales INT
     );

    -- 2. Preparar BULK INSERT (corregido para ; y formato Linux/UTF-8)
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    BULK INSERT #temp_consorcios
    FROM ''' + @ruta_archivo + N'''
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = '';'',     -- Delimitador de punto y coma
        ROWTERMINATOR = ''\n''
    );
    ';

    -- 3. Ejecutar la importación a la tabla temporal
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error durante el BULK INSERT. Verifique la ruta del archivo, los permisos y el formato.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS #temp_consorcios;
        RETURN;
    END CATCH

    -- 4. Inserto los datos en la tabla final (CORREGIDO)
    --    (Se insertan solo las columnas que existen en ddbba.consorcio)
    INSERT INTO ddbba.consorcio (
        nombre,                 -- Columna 'nombre' de la tabla final
        metros_cuadrados,       -- Columna 'metros_cuadrados' de la tabla final
        direccion,
        cant_UF
    )
    SELECT
        t.nombre,               -- Viene de la columna 'nombre' del CSV
        t.M2_totales,           -- Viene de la columna 'm2 totales' del CSV
        t.domicilio,          -- Viene de la columna 'Domicilio' del CSV
        t.cant_UF
    FROM #temp_consorcios AS t
    WHERE NOT EXISTS (
        SELECT 1 FROM ddbba.consorcio c
        where c.nombre = t.nombre
    )

    
END;
GO
