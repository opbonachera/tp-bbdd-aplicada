CREATE OR ALTER PROCEDURE ddbba.sp_importar_servicios
	@ruta_archivo NVARCHAR(500),
    @Anio INT = 2025 --Parametrizamos el anio para poder cambiarlo mas facilmente si lo necesitamos
AS
BEGIN
	
	DECLARE @json NVARCHAR(MAX);
	
    --Usamos SQL dinamico para abrir el JSON
	DECLARE @sql NVARCHAR(MAX);
	SET @sql = N'SELECT @jsonOut = BulkColumn FROM OPENROWSET(BULK ''' + @ruta_archivo + ''', SINGLE_CLOB) AS datos';
	EXEC sp_executesql @SQL, N'@jsonOut NVARCHAR(MAX) OUTPUT', @jsonOut = @json OUTPUT;
	
    --En el caso de que no encuentre el archivo, avisa y termina
    IF @json IS NULL
	BEGIN
		PRINT 'Error: No se pudo leer el archivo JSON.';
		RETURN;
	END

	IF OBJECT_ID('tempdb..#tempConsorcios') IS NOT NULL DROP TABLE #tempConsorcios;

    --Creamos tabla temporal para los consorcios
    CREATE TABLE #tempConsorcios (
        nombre_consorcio NVARCHAR(255),
        mes NVARCHAR(50),
        bancarios NVARCHAR(50),
        limpieza NVARCHAR(50),
        administracion NVARCHAR(50),
        seguros NVARCHAR(50),
        gastos_generales NVARCHAR(50),
        servicios_agua NVARCHAR(50),
        servicios_luz NVARCHAR(50),
        servicios_internet NVARCHAR(50)
    );

    --Insertamos los datos en la tabla temporal
    INSERT INTO #tempConsorcios (nombre_consorcio, mes, bancarios, limpieza, administracion, seguros,
                                 gastos_generales, servicios_agua, servicios_luz, servicios_internet)
    SELECT *
    FROM OPENJSON(@json)
    WITH (
        nombre_consorcio NVARCHAR(255) '$."Nombre del consorcio"',
        mes NVARCHAR(50) '$.Mes',
        bancarios NVARCHAR(50) '$.BANCARIOS',
        limpieza NVARCHAR(50) '$.LIMPIEZA',
        administracion NVARCHAR(50) '$.ADMINISTRACION',
        seguros NVARCHAR(50) '$.SEGUROS',
        gastos_generales NVARCHAR(50) '$."GASTOS GENERALES"',
        servicios_agua NVARCHAR(50) '$."SERVICIOS PUBLICOS-Agua"',
        servicios_luz NVARCHAR(50) '$."SERVICIOS PUBLICOS-Luz"',
        servicios_internet NVARCHAR(50) '$."SERVICIOS PUBLICOS-Internet"'
    );

    --Normalizamos el texto (eliminamos espacios de strings y normalizamos valores numericos)
    UPDATE #tempConsorcios
    SET
        nombre_consorcio = nombre_consorcio,
        mes = ddbba.fn_limpiar_espacios(mes),
        bancarios = ddbba.fn_normalizar_monto(bancarios),
        limpieza = ddbba.fn_normalizar_monto(limpieza),
        administracion = ddbba.fn_normalizar_monto(administracion),
        seguros = ddbba.fn_normalizar_monto(seguros),
        gastos_generales = ddbba.fn_normalizar_monto(gastos_generales),
        servicios_agua = ddbba.fn_normalizar_monto(servicios_agua),
        servicios_luz = ddbba.fn_normalizar_monto(servicios_luz),
        servicios_internet = ddbba.fn_normalizar_monto(servicios_internet);

    --Insertamos los tipos de gasto existentes
    INSERT INTO ddbba.tipo_gasto (detalle)
    SELECT detalle
    FROM (VALUES ('BANCARIOS'), ('LIMPIEZA'), ('ADMINISTRACION'), ('SEGUROS'),
           ('GASTOS GENERALES'), ('SERVICIOS PUBLICOS-Agua'), 
           ('SERVICIOS PUBLICOS-Luz'), ('SERVICIOS PUBLICOS-Internet')
    ) AS t(detalle)
    WHERE NOT EXISTS (
        SELECT 1 FROM ddbba.tipo_gasto g WHERE g.detalle = t.detalle
    );

    --Insertamos expensas (una por cada consorcio y mes)
    INSERT INTO ddbba.expensa (id_consorcio, fecha_emision)
    SELECT DISTINCT c.id_consorcio,
     TRY_CONVERT(DATE, CONCAT('01-', m.mes_num, '-', @Anio), 105)
	FROM #tempConsorcios tc
	INNER JOIN ddbba.consorcio c ON c.nombre = tc.nombre_consorcio
	--Creo que para date si o si necesitamos una fecha completa asi que concatenamos con una fecha referencial (el primero del mes) y convertimos el mes a numero usando cross apply
    CROSS APPLY (
        SELECT CASE LOWER(LTRIM(RTRIM(tc.mes)))
            WHEN 'enero' THEN '01'
            WHEN 'febrero' THEN '02'
            WHEN 'marzo' THEN '03'
            WHEN 'abril' THEN '04'
            WHEN 'mayo' THEN '05'
            WHEN 'junio' THEN '06'
            WHEN 'julio' THEN '07'
            WHEN 'agosto' THEN '08'
            WHEN 'septiembre' THEN '09'
            WHEN 'octubre' THEN '10'
            WHEN 'noviembre' THEN '11'
            WHEN 'diciembre' THEN '12'
            ELSE NULL
        END AS mes_num
    ) AS m
    WHERE NOT EXISTS (
		SELECT 1 FROM ddbba.expensa e
		WHERE e.id_consorcio = c.id_consorcio
		  AND e.fecha_emision = TRY_CONVERT(DATE, CONCAT('01-', m.mes_num, '-', @Anio), 105)
        
	);

	-- Insertamos los gastos ordinarios
	-- Insertamos los gastos ordinarios
        INSERT INTO ddbba.gastos_ordinarios (id_expensa, id_tipo_gasto, detalle, nro_factura, importe)
        SELECT 
	        e.id_expensa,
	        t.id_tipo_gasto,
	        t.detalle AS detalle,
	        NULL AS nro_factura,
	        CASE t.detalle
		        WHEN 'BANCARIOS' THEN TRY_CAST(tc.bancarios AS DECIMAL(12,2))
		        WHEN 'LIMPIEZA' THEN TRY_CAST(tc.limpieza AS DECIMAL(12,2))
		        WHEN 'ADMINISTRACION' THEN TRY_CAST(tc.administracion AS DECIMAL(12,2))
		        WHEN 'SEGUROS' THEN TRY_CAST(tc.seguros AS DECIMAL(12,2))
		        WHEN 'GASTOS GENERALES' THEN TRY_CAST(tc.gastos_generales AS DECIMAL(12,2))
		        WHEN 'SERVICIOS PUBLICOS-Agua' THEN TRY_CAST(tc.servicios_agua AS DECIMAL(12,2))
		        WHEN 'SERVICIOS PUBLICOS-Luz' THEN TRY_CAST(tc.servicios_luz AS DECIMAL(12,2))
		        WHEN 'SERVICIOS PUBLICOS-Internet' THEN TRY_CAST(tc.servicios_internet AS DECIMAL(12,2))
	        END AS importe
        FROM #tempConsorcios tc
        INNER JOIN ddbba.consorcio c ON c.nombre = tc.nombre_consorcio
        CROSS APPLY (
            SELECT CASE LOWER(LTRIM(RTRIM(tc.mes)))
                WHEN 'enero' THEN '01'
                WHEN 'febrero' THEN '02'
                WHEN 'marzo' THEN '03'
                WHEN 'abril' THEN '04'
                WHEN 'mayo' THEN '05'
                WHEN 'junio' THEN '06'
                WHEN 'julio' THEN '07'
                WHEN 'agosto' THEN '08'
                WHEN 'septiembre' THEN '09'
                WHEN 'octubre' THEN '10'
                WHEN 'noviembre' THEN '11'
                WHEN 'diciembre' THEN '12'
                ELSE NULL
            END AS mes_num
        ) AS m
        INNER JOIN ddbba.expensa e ON e.id_consorcio = c.id_consorcio
	        AND e.fecha_emision = TRY_CONVERT(DATE, CONCAT('01-', m.mes_num, '-', @Anio), 105)
        CROSS JOIN ddbba.tipo_gasto t
        WHERE (
	        (t.detalle = 'BANCARIOS' AND tc.bancarios IS NOT NULL) OR
	        (t.detalle = 'LIMPIEZA' AND tc.limpieza IS NOT NULL) OR
	        (t.detalle = 'ADMINISTRACION' AND tc.administracion IS NOT NULL) OR
	        (t.detalle = 'SEGUROS' AND tc.seguros IS NOT NULL) OR
	        (t.detalle = 'GASTOS GENERALES' AND tc.gastos_generales IS NOT NULL) OR
	        (t.detalle = 'SERVICIOS PUBLICOS-Agua' AND tc.servicios_agua IS NOT NULL) OR
	        (t.detalle = 'SERVICIOS PUBLICOS-Luz' AND tc.servicios_luz IS NOT NULL) OR
	        (t.detalle = 'SERVICIOS PUBLICOS-Internet' AND tc.servicios_internet IS NOT NULL)
        )
        AND NOT EXISTS (
	        SELECT 1 FROM ddbba.gastos_ordinarios gaor
	        WHERE gaor.id_expensa = e.id_expensa
	          AND gaor.id_tipo_gasto = t.id_tipo_gasto
        );

	PRINT 'Datos importados.';

END
GO


--ejecuto el sp (chequear ruta de archivo)
EXEC ddbba.sp_importar_servicios 
	@ruta_archivo = '\app\datasets\tp\Servicios.Servicios.json';
GO

-- EXTRA:
--chequeo que los datos se hayan insertado correctamente
SELECT * FROM ddbba.consorcio;
SELECT * FROM ddbba.expensa;
SELECT * FROM ddbba.tipo_gasto;
SELECT count(importe)
FROM ddbba.gastos_ordinarios
group by importe;
GO

select sum(importe)
from ddbba.gastos_ordinarios
group by id_tipo_gasto

SELECT 
    c.nombre AS consorcio,
    SUM(go.importe) AS total_gastos_generales
FROM ddbba.gastos_ordinarios go
INNER JOIN ddbba.expensa e ON e.id_expensa = go.id_expensa
INNER JOIN ddbba.consorcio c ON c.id_consorcio = e.id_consorcio
INNER JOIN ddbba.tipo_gasto tg ON tg.id_tipo_gasto = go.id_tipo_gasto
WHERE tg.detalle = 'GASTOS GENERALES'
GROUP BY c.nombre
ORDER BY c.nombre;

