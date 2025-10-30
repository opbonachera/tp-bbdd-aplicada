CREATE OR ALTER PROCEDURE ddbba.ImportarConsorcios
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        
       
        -- 1. Verificar acceso al archivo (solo lectura)
       
        DECLARE @Comando NVARCHAR(1000);
        SET @Comando = 'dir "' + @RutaArchivo + '"';

        DECLARE @Resultado TABLE (Linea NVARCHAR(4000));
        INSERT INTO @Resultado
        EXEC xp_cmdshell @Comando;

        IF NOT EXISTS (SELECT 1 FROM @Resultado WHERE Linea LIKE '%' + PARSENAME(@RutaArchivo, 1) + '%')
        BEGIN
            RAISERROR('El archivo no existe o no se puede acceder a la ruta especificada.', 16, 1);
            RETURN;
        END;



        -- 2. Crear tabla temporal para carga inicial
      
        CREATE TABLE #ConsorciosTemp (
            NombreConsorcio NVARCHAR(100),
            nroUnidadFuncional INT,
            Piso INT,
            Departamento NVARCHAR(10),
            Coeficiente DECIMAL(10,4),
            m2_unidad_funcional DECIMAL(10,2),
            Bauleras INT,
            Cochera INT,
            m2_baulera DECIMAL(10,2),
            m2_cochera DECIMAL(10,2)
        );


        -- 3. Cargar datos desde el archivo (SQL din�mico)
       
        DECLARE @SQL NVARCHAR(MAX);

        SET @SQL = N'
            BULK INSERT #ConsorciosTemp
            FROM ''' + @RutaArchivo + N'''
            WITH (
                FIRSTROW = 2,               -- Ignora la fila de encabezados
                FIELDTERMINATOR = ''\t'',   -- Tabulaci�n
                ROWTERMINATOR = ''\n'',     -- Fin de l�nea
                CODEPAGE = ''65001'',       -- UTF-8
                DATAFILETYPE = ''widechar'',
                TABLOCK
            );
        ';

        PRINT 'Ejecutando importaci�n desde: ' + @RutaArchivo;
        EXEC sp_executesql @SQL;


        -- 4. Insertar en tabla definitiva
        
        INSERT INTO ddbba.Consorcios (
            NombreConsorcio, nroUnidadFuncional, Piso, Departamento,
            Coeficiente, m2_unidad_funcional, Bauleras, Cochera,
            m2_baulera, m2_cochera
        )
        SELECT
            NombreConsorcio, nroUnidadFuncional, Piso, Departamento,
            Coeficiente, m2_unidad_funcional, Bauleras, Cochera,
            m2_baulera, m2_cochera
        FROM #ConsorciosTemp;


       
        -- 5. Mensaje de confirmaci�n
       
        DECLARE @Total INT = (SELECT COUNT(*) FROM #ConsorciosTemp);
        PRINT ' Importaci�n completada correctamente. ' 
              + CAST(@Total AS NVARCHAR(10)) + ' registros insertados.';

    END TRY
    BEGIN CATCH
        PRINT ' Error durante la importaci�n:';
        PRINT ERROR_MESSAGE();
    END CATCH
   
    -- 6. Limpieza de tabla temporal
   
    DROP TABLE IF EXISTS #ConsorciosTemp;

END;
GO
