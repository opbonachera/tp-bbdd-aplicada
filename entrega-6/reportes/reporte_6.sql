--  Reporte 6

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_6
    @id_unidad_funcional INT = NULL,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH PagosUnicos AS (
        SELECT DISTINCT
            p.id_unidad_funcional,
            p.id_expensa,
            CAST(p.fecha_pago AS DATE) AS fecha_pago
        FROM ddbba.pago p
        INNER JOIN ddbba.expensa e ON p.id_expensa = e.id_expensa
        INNER JOIN ddbba.gastos_ordinarios go ON e.id_expensa = go.id_expensa
        INNER JOIN ddbba.unidad_funcional uf ON p.id_unidad_funcional = uf.id_unidad_funcional
        WHERE
            (@id_unidad_funcional IS NULL OR p.id_unidad_funcional = @id_unidad_funcional)
            AND (@fecha_desde IS NULL OR p.fecha_pago >= @fecha_desde)
            AND (@fecha_hasta IS NULL OR p.fecha_pago <= @fecha_hasta)
    ),
    PagosConLag AS (
        SELECT
            *,
            LAG(fecha_pago) OVER (PARTITION BY id_unidad_funcional ORDER BY fecha_pago) AS Fecha_Pago_Anterior
        FROM PagosUnicos
    )
    SELECT
        id_unidad_funcional,
        id_expensa,
        fecha_pago,
        Fecha_Pago_Anterior,
        DATEDIFF(DAY, Fecha_Pago_Anterior, fecha_pago) AS Dias_Entre_Pagos
    FROM PagosConLag
    ORDER BY id_unidad_funcional, fecha_pago;
END
GO

 



-- 1️⃣ Todos los pagos de todas las UF
EXEC ddbba.sp_reporte_6;

-- 2️⃣ Solo pagos del UF 1
EXEC ddbba.sp_reporte_6 @id_unidad_funcional = 1;

-- 3️⃣ Pagos entre enero y marzo de 2025
EXEC ddbba.sp_reporte_6 @fecha_desde = '2025-01-01', @fecha_hasta = '2025-03-31';

-- 4️⃣ Pagos del UF 2 entre febrero y abril
EXEC ddbba.sp_reporte_6 @id_unidad_funcional = 2, @fecha_desde = '2025-02-01', @fecha_hasta = '2025-04-30';


