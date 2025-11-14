CREATE OR ALTER PROCEDURE ddbba.sp_reporte_2
    @min  DECIMAL(12,2) = NULL, 
    @max  DECIMAL(12,2) = NULL,
    @anio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cols NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @where NVARCHAR(MAX) = N' WHERE 1=1 ';
    DECLARE @having NVARCHAR(MAX) = N'';

    -- filtro por año (aplica sobre filas antes de agrupar)
    IF @anio IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) = @anio ';

    -- filtros sobre la suma agregada (se usan en HAVING)
    IF @min IS NOT NULL AND @max IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) BETWEEN @min AND @max ';
    ELSE IF @min IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) >= @min ';
    ELSE IF @max IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) <= @max ';

    -- Columnas dinámicas (departamentos)
    SELECT @cols = STRING_AGG(QUOTENAME(departamento), ',')
    FROM (SELECT DISTINCT departamento FROM ddbba.unidad_funcional) AS d;

    -- SQL dinámico con WHERE + GROUP BY + HAVING
    SET @sql = N'
        WITH mes_uf_CTE AS (
            SELECT 
                FORMAT(p.fecha_pago, ''yyyy-MM'') AS mes, 
                uf.departamento,
                SUM(p.monto) AS total_monto
            FROM ddbba.pago p
            JOIN ddbba.unidad_funcional uf  
                ON uf.id_unidad_funcional = p.id_unidad_funcional
            ' + @where + N'
            GROUP BY FORMAT(p.fecha_pago, ''yyyy-MM''), uf.departamento
            ' + @having + N'
        )
        SELECT mes, ' + @cols + N'
        FROM mes_uf_CTE
        PIVOT (
            SUM(total_monto)
            FOR departamento IN (' + @cols + N')
        ) AS tabla_cruzada
        ORDER BY mes
        FOR XML PATH(''Mes''), ROOT(''Recaudacion''), ELEMENTS XSINIL;';

    -- Ejecutar con parámetros
    EXEC sp_executesql 
        @sql,
        N'@min DECIMAL(12,2), @max DECIMAL(12,2), @anio INT',
        @min=@min, @max=@max, @anio=@anio;
END;
GO

exec ddbba.sp_reporte_2 @min= 74000