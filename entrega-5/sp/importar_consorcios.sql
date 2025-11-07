CREATE OR ALTER PROCEDURE ddbba.sp_importar_consorcios
	@NomArch varchar(255)
AS
BEGIN
 
-- 1. Creacion de la tabla temporal
 CREATE TABLE #temp_consorcios
 ( consorcio varchar(12),
   nombre varchar(50),
   domicilio varchar (50),
   cant_UF smallint,
   M2_totales int
  );
 
-- 2. Inserto los datos del archivo excel a la tabla temporal (SQL Dinámico)
   DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        INSERT INTO #temp_consorcios (consorcio, nombre, domicilio, cant_UF, M2_totales)
        SELECT Consorcio, [Nombre del consorcio], Domicilio, [Cant unidades funcionales], [m2 totales]
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;Database=' + @NomArch + ';HDR=YES'',
            ''SELECT * FROM [Consorcios$]''
        );
    ';

-- 3. Ejecuto el sql dinamico
    EXEC sp_executesql @sql;

-- 4. Inserto los datos en la tabla original (SECCIÓN MODIFICADA)

	-- Usamos un CTE (Common Table Expression) para manejar los duplicados
	;WITH OrigenDeduplicado AS (
		SELECT
			t.nombre,
			t.M2_totales,
			t.domicilio,
			t.cant_UF,
			-- Asignamos un número de fila a cada 'nombre' duplicado en el archivo
			-- Se prioriza por el ID 'consorcio' (usado solo para ordenar)
			ROW_NUMBER() OVER (PARTITION BY t.nombre ORDER BY t.consorcio) AS rn
		FROM
			#temp_consorcios AS t
	)
	-- Inserto en la tabla final
	INSERT INTO ddbba.consorcio(
	    nombre,
	    metros_cuadrados ,
	    direccion,
		cant_UF
	)
	SELECT
		od.nombre,
		od.M2_totales,
		od.domicilio,
		od.cant_UF
	FROM
		OrigenDeduplicado AS od
	WHERE
		-- REQ 1: Solo tomamos el primero que apareció en el archivo Excel
		od.rn = 1
		-- REQ 2: Y que no exista ya en la tabla de destino (revisando por 'nombre')
		AND NOT EXISTS (
			SELECT 1
			FROM ddbba.consorcio AS dest
			WHERE dest.nombre = od.nombre
		);

-- 5. Elimino la tabla temporal
	DROP TABLE #temp_consorcios
END