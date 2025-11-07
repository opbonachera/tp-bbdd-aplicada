create or alter procedure sp_reporte_1
as
begin
    -- Creamos una CTE para calcular la recaudación semanal. De aca obtenemos: total de gastos ordinarios y extraordinarios por semana
    WITH RecaudacionSemanal AS (
        SELECT 
            DATEPART(WEEK, p.fecha_pago) AS semana,
            SUM(CASE WHEN go.id_gasto_ordinario IS NOT NULL THEN p.monto ELSE 0 END) AS total_ordinarios,
            SUM(CASE WHEN ge.id_gasto_extraordinario IS NOT NULL THEN p.monto ELSE 0 END) AS total_extraordinarios
        FROM ddbba.pago p
        LEFT JOIN ddbba.expensa e ON e.id_expensa = p.id_expensa
        LEFT JOIN ddbba.gastos_ordinarios go ON go.id_expensa = e.id_expensa
        LEFT JOIN ddbba.gasto_extraordinario ge ON ge.id_expensa = e.id_expensa
        GROUP BY DATEPART(WEEK, p.fecha_pago)
    )
    -- Obtenemos las columnas finales del reporte
    SELECT 
        semana,
        total_ordinarios,
        total_extraordinarios,
        (total_ordinarios + total_extraordinarios) AS total_semanal,
        AVG(total_ordinarios + total_extraordinarios) OVER () AS promedio_general,
        SUM(total_ordinarios + total_extraordinarios) OVER (ORDER BY semana) AS acumulado_progresivo
    FROM RecaudacionSemanal
    ORDER BY semana;
end

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_2
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cols NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);

    -- 1. Obtener la lista de columnas (departamentos) dinámicamente
    SELECT @cols = STRING_AGG(QUOTENAME(departamento), ',')
    FROM (SELECT DISTINCT departamento FROM ddbba.unidad_funcional) AS d;

    -- 2. Armar el SQL dinámico 
    SET @sql = N'
    WITH mes_uf_CTE AS (
        SELECT 
            FORMAT(p.fecha_pago, ''yyyy-MM'') AS mes, 
            uf.departamento,
            SUM(p.monto) AS total_monto
        FROM ddbba.pago p  
        JOIN ddbba.unidad_funcional uf  
            ON uf.id_unidad_funcional = p.id_unidad_funcional
        GROUP BY FORMAT(p.fecha_pago, ''yyyy-MM''), uf.departamento 
    )
    SELECT mes, ' + @cols + N'
    FROM mes_uf_CTE -- Nombre del CTE actualizado aquí
    PIVOT (
        SUM(total_monto)
        FOR departamento IN (' + @cols + N')
    ) AS tabla_cruzada
    ORDER BY mes;'; 

    -- 3. Ejecutar la consulta dinámica
    PRINT 'SQL dinámico a ejecutar:';
    PRINT @sql;
    EXEC sp_executesql @sql;
END;
GO



