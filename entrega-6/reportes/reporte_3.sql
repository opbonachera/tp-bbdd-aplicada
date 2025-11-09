
CREATE OR ALTER PROCEDURE ddbba.sp_reporte_3
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @IdConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH gastos_union AS (
        SELECT 
            FORMAT(e.fecha_emision, 'yyyy-MM') AS Periodo,
            'Ordinario' AS Tipo,
            go.importe AS Importe
        FROM ddbba.expensa e
        INNER JOIN ddbba.gastos_ordinarios go 
            ON e.id_expensa = go.id_expensa
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
        ISNULL([Ordinario], 0) + ISNULL([Extraordinario], 0) AS Total_Recaudado
    FROM gastos_union
    PIVOT (
        SUM(Importe)
        FOR Tipo IN ([Ordinario], [Extraordinario])
    ) AS pvt
    ORDER BY Periodo;
END;
GO

--Formas de ejecución

--1. Sin parámetros
exec ddbba.sp_reporte_3;
--2. Con parámetros de fecha
exec ddbba.sp_reporte_3 
    @FechaDesde = '2025-01-01',
    @FechaHasta = '2025-04-30';
--3. Con ID de consorcio
exec ddbba.sp_reporte_3 
    @IdConsorcio = 2;

