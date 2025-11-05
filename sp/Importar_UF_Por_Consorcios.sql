--IMPORTAR UF POR CONSORCIOS
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
	
	SELECT *
	FROM #temp_UF t
	LEFT JOIN ddbba.consorcio c ON c.nombre = t.nom_consorcio
	WHERE c.id_consorcio IS NULL;

	DELETE t
	FROM #temp_UF t
	INNER JOIN ddbba.consorcio c ON c.nombre = t.nom_consorcio
	INNER JOIN ddbba.unidad_funcional uf 
		ON uf.id_unidad_funcional = t.num_UF
		AND uf.id_consorcio = c.id_consorcio;


	INSERT INTO [ddbba].[unidad_funcional] (id_unidad_funcional, id_consorcio, metros_cuadrados, piso, departamento, cochera, baulera, coeficiente)
	SELECT 
		t.num_UF,
		c.id_consorcio,
		(t.m2_UF+t.m2_baulera+t.m2_cochera) as metros_cuadrados, --SE SUMA TODO PARA SABER LA CANTD DE M2 DE ESA UF
		t.piso,
		t.departamento,
		CASE 
			WHEN LTRIM(RTRIM(UPPER(t.cochera))) IN ('SI','SÍ') THEN 1 ELSE 0
		END,
		CASE 
			WHEN LTRIM(RTRIM(UPPER(t.baulera))) IN ('SI','SÍ') THEN 1 ELSE 0
		END, --PARA CAMBIAR EL SI O NO POR EL BIT 1 o 0
		TRY_CAST(REPLACE(t.coeficiente, ',', '.') AS DECIMAL(6,3)) AS coeficiente
	FROM #temp_UF as t
	INNER JOIN ddbba.consorcio as c
		ON c.nombre= t.nom_consorcio ---PARA PONER EL LA TABLA DE UF EL ID DE CONSORCIO

	--ELIMINO LA TABLA TEMPORAL
	DROP TABLE #temp_UF
END
GO
    
-- --PARA EJECUTAR EL SP
-- EXEC ddbba.sp_importar_uf_por_consorcios
-- 		@ruta_archivo='C:\Users\Usuario\Desktop\TPBASEDDATOS\documentacion\Archivos para el TP/UF por consorcio.txt'

-- --PARA VER SI INSERTO CORRECTAMENTE
-- select * from [ddbba].[unidad_funcional]

exec ddbba.sp_importar_uf_por_consorcios @ruta_archivo = 'C:\Users\leafnoise\Documents\Ornella\Proyectos\tp-bbdd-aplicada\documentacion\Archivos para el TP\UF por consorcio.txt'
	