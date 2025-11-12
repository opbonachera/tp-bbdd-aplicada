CREATE OR ALTER PROCEDURE ddbba.sp_reporte_1
    @id_consorcio INT = NULL, 
    @anio_desde INT = NULL,   
    @anio_hasta INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @where NVARCHAR(MAX) = N' WHERE 1=1 ';

    -- Filtros: cada uno es independiente
    IF @id_consorcio IS NOT NULL
        SET @where += N' AND e.id_consorcio = @id_consorcio ';

    IF @anio_desde IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) >= @anio_desde ';

    IF @anio_hasta IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) <= @anio_hasta ';

    -- CTE: recaudación semanal
    SET @sql = N'
        WITH RecaudacionSemanal AS (
            SELECT 
                DATEPART(WEEK, p.fecha_pago) AS semana,
                SUM(CASE WHEN go.id_gasto_ordinario IS NOT NULL THEN p.monto ELSE 0 END) AS total_ordinarios,
                SUM(CASE WHEN ge.id_gasto_extraordinario IS NOT NULL THEN p.monto ELSE 0 END) AS total_extraordinarios
            FROM ddbba.pago p
            LEFT JOIN ddbba.expensa e ON e.id_expensa = p.id_expensa
            LEFT JOIN ddbba.gastos_ordinarios go ON go.id_expensa = e.id_expensa
            LEFT JOIN ddbba.gasto_extraordinario ge ON ge.id_expensa = e.id_expensa
            ' + @where + N'
            GROUP BY DATEPART(WEEK, p.fecha_pago)
        )
        SELECT 
            semana,
            total_ordinarios,
            total_extraordinarios,
            (total_ordinarios + total_extraordinarios) AS total_semanal,
            AVG(total_ordinarios + total_extraordinarios) OVER () AS promedio_general,
            SUM(total_ordinarios + total_extraordinarios) OVER (ORDER BY semana) AS acumulado_progresivo
        FROM RecaudacionSemanal
        ORDER BY semana;';

    -- Ejecutar consulta
    EXEC sp_executesql 
        @sql,
        N'@id_consorcio INT, @anio_desde INT, @anio_hasta INT',
        @id_consorcio=@id_consorcio, @anio_desde=@anio_desde, @anio_hasta=@anio_hasta;
END;
GO


exec ddbba.sp_reporte_1 @id_consorcio=3