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
    
------------------------------------------------------------------------------------------------------
/*Reporte 4 con XML
Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos*/
CREATE OR ALTER PROCEDURE ddbba.sp_reporte_4
    @id_consorcio INT = NULL,  -- filtrar por consorcio
    @AnioDesde INT = NULL,     -- año desde
    @AnioHasta INT = NULL      --  año hasta
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FechaDesde DATE = NULL;
    DECLARE @FechaHasta DATE = NULL;

    -- Rango de fechas
    IF @AnioDesde IS NOT NULL
        SET @FechaDesde = DATEFROMPARTS(@AnioDesde, 1, 1);
    IF @AnioHasta IS NOT NULL
        SET @FechaHasta = DATEFROMPARTS(@AnioHasta, 12, 31);


-- TOP 5 MESES CON MAYORES GASTOS (Ordinarios + Extraordinarios)

    ;WITH GastosUnificados AS (
        SELECT 
            YEAR(e.fecha_emision) AS Anio,
            MONTH(e.fecha_emision) AS Mes,
            gor.importe AS Monto,
            'Ordinario' AS TipoGasto,
            e.id_consorcio
        FROM ddbba.gastos_ordinarios gor
        INNER JOIN ddbba.expensa e ON gor.id_expensa = e.id_expensa
        WHERE 
            (@id_consorcio IS NULL OR e.id_consorcio = @id_consorcio)
            AND (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)

        UNION ALL

        SELECT 
            YEAR(e.fecha_emision) AS Anio,
            MONTH(e.fecha_emision) AS Mes,
            ge.importe_total AS Monto,
            'Extraordinario' AS TipoGasto,
            e.id_consorcio
        FROM ddbba.gasto_extraordinario ge
        INNER JOIN ddbba.expensa e ON ge.id_expensa = e.id_expensa
        WHERE 
            (@id_consorcio IS NULL OR e.id_consorcio = @id_consorcio)
            AND (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)
    ),
    GastosMensuales AS (
        SELECT 
            Anio,
            Mes,
            DATENAME(MONTH, DATEFROMPARTS(Anio, Mes, 1)) AS NombreMes,
            SUM(Monto) AS TotalGastos,
            SUM(CASE WHEN TipoGasto = 'Ordinario' THEN Monto ELSE 0 END) AS GastosOrdinarios,
            SUM(CASE WHEN TipoGasto = 'Extraordinario' THEN Monto ELSE 0 END) AS GastosExtraordinarios,
            COUNT(*) AS CantidadGastos,
            COUNT(CASE WHEN TipoGasto = 'Ordinario' THEN 1 END) AS CantOrdinarios,
            COUNT(CASE WHEN TipoGasto = 'Extraordinario' THEN 1 END) AS CantExtraordinarios
        FROM GastosUnificados
        GROUP BY Anio, Mes
    )
    SELECT TOP 5
        Anio AS [@Anio],
        Mes AS [@Mes],
        NombreMes AS [@NombreMes],
        TotalGastos AS [@TotalGastos],
        GastosOrdinarios AS [@GastosOrdinarios],
        GastosExtraordinarios AS [@GastosExtraordinarios],
        CantidadGastos AS [@CantidadGastos],
        CantOrdinarios AS [@CantOrdinarios],
        CantExtraordinarios AS [@CantExtraordinarios],
        CAST(Anio AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(Mes AS VARCHAR(2)), 2) AS [@PeriodoOrdenado]
    FROM GastosMensuales
    ORDER BY TotalGastos DESC
    FOR XML PATH('Mes'), ROOT('Top5MesesGastos'), TYPE;


--  TOP 5 MESES CON MAYORES INGRESOS

    ;WITH IngresosMensuales AS (
        SELECT 
            YEAR(p.fecha_pago) AS Anio,
            MONTH(p.fecha_pago) AS Mes,
            DATENAME(MONTH, p.fecha_pago) AS NombreMes,
            SUM(p.monto) AS TotalIngresos,
            COUNT(*) AS CantidadPagos,
            COUNT(DISTINCT p.id_unidad_funcional) AS UnidadesPagaron
        FROM ddbba.pago p
        WHERE 
            p.estado = 'Aprobado'
            AND (@id_consorcio IS NULL OR p.id_consorcio = @id_consorcio)
            AND (@FechaDesde IS NULL OR p.fecha_pago >= @FechaDesde)
            AND (@FechaHasta IS NULL OR p.fecha_pago <= @FechaHasta)
        GROUP BY 
            YEAR(p.fecha_pago),
            MONTH(p.fecha_pago),
            DATENAME(MONTH, p.fecha_pago)
    )
    ---genera el XML
    SELECT TOP 5
        Anio AS [@Anio],
        Mes AS [@Mes],
        NombreMes AS [@NombreMes],
        TotalIngresos AS [@TotalIngresos],
        CantidadPagos AS [@CantidadPagos],
        UnidadesPagaron AS [@UnidadesPagaron],
        CAST(Anio AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(Mes AS VARCHAR(2)), 2) AS [@PeriodoOrdenado]
    FROM IngresosMensuales
    ORDER BY TotalIngresos DESC
    FOR XML PATH('Mes'), ROOT('Top5MesesIngresos'), TYPE;

END;
GO

--TEST 
EXEC ddbba.sp_reporte_4;-- sin parametros de entrada
EXEC ddbba.sp_reporte_4 @id_consorcio = 5; --mandadole un consorcio
EXEC ddbba.sp_reporte_4 @AnioDesde = 2025, @AnioHasta = 2025; --mandadole años
EXEC ddbba.sp_reporte_4 @id_consorcio = 1, @AnioDesde = 2025, @AnioHasta = 2025;--mandadole todos los parametos


