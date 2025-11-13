CREATE OR ALTER PROCEDURE ddbba.sp_reporte_3
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @IdConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -----------------------------------------------------------
    -- 1. Obtener el valor del dólar oficial (value_buy)
    -----------------------------------------------------------
    DECLARE @url NVARCHAR(256) = 'https://api.bluelytics.com.ar/v2/latest';
    DECLARE @Object INT;
    DECLARE @json TABLE(DATA NVARCHAR(MAX));
    DECLARE @datos NVARCHAR(MAX);
    DECLARE @valor_dolar DECIMAL(10,2);
    DECLARE @fecha_dolar DATETIME2;

    BEGIN TRY
        EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
        EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE';
        EXEC sp_OAMethod @Object, 'SEND';
        INSERT INTO @json EXEC sp_OAGetProperty @Object, 'ResponseText';
        EXEC sp_OADestroy @Object;

        SET @datos = (SELECT DATA FROM @json);

        -- Extraemos el valor del dólar y la fecha
        SELECT 
            @valor_dolar = JSON_VALUE(@datos, '$.oficial.value_buy'),
            @fecha_dolar = JSON_VALUE(@datos, '$.last_update');
    END TRY
    BEGIN CATCH
        PRINT 'Error al obtener el valor del dólar. Se usará 1 como valor por defecto.';
        SET @valor_dolar = 1;
        SET @fecha_dolar = GETDATE();
    END CATCH;

    -- ============================================
    -- CONSULTA PRINCIPAL DE RECAUDACIÓN
    -- ============================================
    WITH gastos_union AS (
        SELECT 
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
    SELECT 
        Periodo,
        ISNULL([Ordinario], 0) AS Total_Ordinario,
        ISNULL([Extraordinario], 0) AS Total_Extraordinario,
        ISNULL([Ordinario], 0) + ISNULL([Extraordinario], 0) AS Total_Recaudado,
        CAST(ROUND((ISNULL([Ordinario], 0) + ISNULL([Extraordinario], 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Recaudado_USD
    FROM gastos_union
    PIVOT (
        SUM(Importe)
        FOR Tipo IN ([Ordinario], [Extraordinario])
    ) AS pvt
    ORDER BY Periodo;

END;

GO

