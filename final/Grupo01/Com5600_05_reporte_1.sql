/*
    Reporte 1
    Flujo de caja semanal:
    - Total recaudado por semana
    - Promedio en el periodo
    - Acumulado progresivo
*/

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_1
    @id_consorcio INT = NULL, 
    @anio_desde INT = NULL,   
    @anio_hasta INT = NULL
WITH EXECUTE AS owner
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @where NVARCHAR(MAX) = N' WHERE 1=1 ';

    -- Filtros dinámicos
    IF @id_consorcio IS NOT NULL
        SET @where += N' AND e.id_consorcio = @id_consorcio ';

    IF @anio_desde IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) >= @anio_desde ';

    IF @anio_hasta IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) <= @anio_hasta ';


    SET @sql = N'
        WITH Pagos AS (
            SELECT
                p.id_pago,
                p.monto,
                p.fecha_pago,
                YEAR(p.fecha_pago) AS anio,
                DATEPART(WEEK, p.fecha_pago) AS semana
            FROM ddbba.pago p
            LEFT JOIN ddbba.expensa e ON e.id_expensa = p.id_expensa
            ' + @where + N'
        ),

        TotalSemanal AS (
            SELECT 
                anio,
                semana,
                SUM(monto) AS total_semanal
            FROM Pagos
            GROUP BY anio, semana
        )

        SELECT 
            anio,
            semana,
            total_semanal,
            AVG(total_semanal) OVER () AS promedio_general,
            SUM(total_semanal) OVER (ORDER BY anio, semana) AS acumulado_progresivo
        FROM TotalSemanal
        ORDER BY anio, semana;
    ';

    EXEC sp_executesql 
        @sql,
        N'@id_consorcio INT, @anio_desde INT, @anio_hasta INT',
        @id_consorcio=@id_consorcio,
        @anio_desde=@anio_desde,
        @anio_hasta=@anio_hasta;
END;
GO

exec ddbba.sp_reporte_1

select sum(p.monto) from ddbba.pago p