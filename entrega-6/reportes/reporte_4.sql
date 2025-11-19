/*
    Reporte 4. 
        Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos. 
*/
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
    --calcula el rango de las fechas segun el parametro pasado
    IF @AnioDesde IS NOT NULL
        SET @FechaDesde = DATEFROMPARTS(@AnioDesde, 1, 1);
    IF @AnioHasta IS NOT NULL
        SET @FechaHasta = DATEFROMPARTS(@AnioHasta, 12, 31);


    -- TOP 5 MESES CON MAYORES GASTOS (Ordinarios + Extraordinarios)
    ;WITH GastosUnificados AS (
        --se obtienen todos los gastos ordinarios segun los filtros pedios
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
          --se obtienen todos los gastos extraordinarios segun los filtros pedios
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
    --se selecciona el top 5 de todos los gastos juntos (ordinarios y extraordinarios) y se lo convierte a xml
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
    --aca se calcula el ingreso por mes teniendo en cuenta solo los pagos aprobados
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