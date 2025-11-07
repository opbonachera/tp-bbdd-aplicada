--IMPORTAR UF POR CONSORCIOS
use "consorcios"
go

CREATE OR ALTER PROCEDURE ddbba.sp_importar_uf_por_consorcios
    @ruta_archivo NVARCHAR(255)
AS
BEGIN
	create table #temp_UF
	(
		nom_consorcio VARCHAR(100),
		num_UF INT,
		piso VARCHAR (10),
		departamento VARCHAR (10),
		coeficiente VARCHAR(10),
		m2_UF INT,
		baulera CHAR(4),
		cochera CHAR(4),
		m2_baulera INT,
		m2_cochera INT
	)


    -- Crear SQL dinámico para BULK INSERT
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'
        BULK INSERT #temp_UF
        FROM ''' + @ruta_archivo + '''
        WITH
        (
            FIELDTERMINATOR = ''\t'',   -- Tabulación
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2       
        );';

    -- Ejecutar SQL dinámico
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error durante el BULK INSERT. Verifique la ruta del archivo, los permisos y el formato.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS #temp_UF;
        RETURN;
    END CATCH
	
	INSERT INTO [ddbba].[unidad_funcional] (
    id_unidad_funcional, id_consorcio, metros_cuadrados, piso, departamento, cochera, baulera, coeficiente
    )
    SELECT  
        t.num_UF,
        c.id_consorcio,
        (t.m2_UF + t.m2_baulera + t.m2_cochera),
        t.piso,
        t.departamento,
        CASE WHEN UPPER(LTRIM(RTRIM(t.cochera))) IN ('SI','SÍ') THEN 1 ELSE 0 END,
        CASE WHEN UPPER(LTRIM(RTRIM(t.baulera))) IN ('SI','SÍ') THEN 1 ELSE 0 END,
        TRY_CAST(REPLACE(t.coeficiente, ',', '.') AS DECIMAL(6,3))
    FROM #temp_UF AS t
    INNER JOIN ddbba.consorcio AS c
        ON LTRIM(RTRIM(UPPER(c.nombre))) = LTRIM(RTRIM(UPPER(t.nom_consorcio)))

	--ELIMINO LA TABLA TEMPORAL
	DROP TABLE #temp_UF
END
GO