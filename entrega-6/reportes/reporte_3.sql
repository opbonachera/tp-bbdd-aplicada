/*
Reporte 3
Presente un cuadro cruzado con la recaudacion total desagregada segun su procedencia (ordinario, extraordinario, etc.) segun el periodo
*/

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_3
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @IdConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Estamos usando una API que devuelve el valor del dolar oficial, blue y el euro en tipo de cambio comprador y vendedor
    --Referencia: https://api.bluelytics.com.ar/

    -- ================================================
    -- Obtener el valor del dolar oficial (value_buy)
    -- ================================================

    --Vamos a convertir el valor total recaudado y sus desgloses a USD oficial, tipo de cambio comprador
    --Para eso, primero armamos el URL del llamado

    DECLARE @url NVARCHAR(256) = 'https://api.bluelytics.com.ar/v2/latest';

    DECLARE @Object INT;
    DECLARE @json TABLE(DATA NVARCHAR(MAX));
    DECLARE @datos NVARCHAR(MAX); --La usaremos para la posterior interpretacion del json
    DECLARE @valor_dolar DECIMAL(10,2);
    DECLARE @fecha_dolar DATETIME2; --Usamos datetime2 porque datetime esta limitada en el rango de anios

    BEGIN TRY
        EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT; -- Creamos una instancia de OLE que nos permite hacer los llamados
        EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE'; -- Definimos algunas propiedades del objeto para hacer una llamada HTTP Get
        EXEC sp_OAMethod @Object, 'SEND';

        --Si el SP devuelve una tabla, lo podemos almacenar con INSERT

        INSERT INTO @json EXEC sp_OAGetProperty @Object, 'ResponseText'; --Obtenemos el valor de la propiedad 'ResponseText' del objeto OLE despues de realizar la consulta
        EXEC sp_OADestroy @Object;

        --Interpretamos el JSON

        SET @datos = (SELECT DATA FROM @json);

        -- Extraemos el valor del dolar y la ultima fecha de actualizacion

        SELECT 
            @valor_dolar = JSON_VALUE(@datos, '$.oficial.value_buy'),
            @fecha_dolar = JSON_VALUE(@datos, '$.last_update');
    END TRY
    BEGIN CATCH
        PRINT 'Error al obtener el valor del dolar. Se usara 1 como valor por defecto.'; --Por si falla
        SET @valor_dolar = 1;
        SET @fecha_dolar = GETDATE();
    END CATCH;

    -- ============================================
    -- Consulta principal de recaudacion
    -- ============================================

    WITH gastos_union AS (
        SELECT

        --Total de Gastos Ordinarios dentro del periodo

            FORMAT(e.fecha_emision, 'yyyy-MM') AS Periodo,
            'Ordinario' AS Tipo,
            gaor.importe AS Importe
        FROM ddbba.expensa e
        INNER JOIN ddbba.gastos_ordinarios gaor 
            ON e.id_expensa = gaor.id_expensa
        WHERE 
            (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)
            AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)

        UNION ALL

        SELECT

        --Total de Gastos Extraordinarios dentro del periodo

            FORMAT(e.fecha_emision, 'yyyy-MM') AS Periodo,
            'Extraordinario' AS Tipo,
            ge.importe_total AS Importe
        FROM ddbba.expensa e
        INNER JOIN ddbba.gasto_extraordinario ge 
            ON e.id_expensa = ge.id_expensa
        WHERE 
            (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)
            AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)
    )

    --Consulta final con los valores desagregados a mostrar

    SELECT 
        Periodo,
        ISNULL([Ordinario], 0) AS Total_Ordinario,
        CAST(ROUND((ISNULL([Ordinario], 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Ordinario_USD, --Casteamos a DECIMAL y redondeamos a dos digitos
        ISNULL([Extraordinario], 0) AS Total_Extraordinario,
        CAST(ROUND((ISNULL(Extraordinario, 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Extraordinario_USD,
        ISNULL([Ordinario], 0) + ISNULL([Extraordinario], 0) AS Total_Recaudado,
        CAST(ROUND((ISNULL([Ordinario], 0) + ISNULL([Extraordinario], 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Recaudado_USD
    FROM gastos_union
    PIVOT (
        SUM(Importe)
        FOR Tipo IN ([Ordinario], [Extraordinario])
    ) AS pvt
    ORDER BY Periodo;


    -- ============================================
    -- Extraer dolar oficial y fecha
    -- ============================================

    --Podemos mostrar el valor del dolar actual y la ultima fecha de actualizacion en una consulta separada
    --para que quien ejecute el reporte este al tanto de que valor se utilizo al momento de ejecutarse el SP

    SELECT 
        CAST(JSON_VALUE(@datos, '$.oficial.value_buy') AS DECIMAL(10,2)) AS Dolar_Oficial_Compra,
        CONVERT(VARCHAR(19), TRY_CAST(JSON_VALUE(@datos, '$.last_update') AS DATETIME2), 120) AS Fecha_Actualizacion

END;

GO

--FORMAS DE EJECUCION DEL SP:

--1. Sin parametros
exec ddbba.sp_reporte_3;
--2. Con parametros de fecha
exec ddbba.sp_reporte_3 
    @FechaDesde = '2025-01-01',
    @FechaHasta = '2025-04-30';
--3. Con ID de consorcio
exec ddbba.sp_reporte_3 
    @IdConsorcio = 2
