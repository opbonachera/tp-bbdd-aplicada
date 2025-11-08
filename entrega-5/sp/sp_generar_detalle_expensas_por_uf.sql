-- Generar detalle de expensas por uf
CREATE OR ALTER PROCEDURE ddbba.sp_generar_detalle_expensas_por_uf
    @cantidad INT = 10 
AS
BEGIN
    SET NOCOUNT ON;


    DECLARE 
        @i INT = 1,
        @id_detalle INT,
        @id_expensa INT,
        @id_unidad_funcional INT,
        @id_consorcio INT,
        @gastos_ordinarios DECIMAL(12,2),
        @gastos_extraordinarios DECIMAL(12,2),
        @valor_cuota DECIMAL(12,2),
        @fecha_1er_vto DATE,
        @fecha_2do_vto DATE,
        @fecha_pago DATE,
        @interes_mora DECIMAL(5,2),
        @deuda DECIMAL(12,2),
        @monto_total DECIMAL(12,2);

 -- 1. Cargar datos base

    DECLARE @Expensas TABLE (id_expensa INT, fecha_1er_vto DATE, fecha_2do_vto DATE);
    DECLARE @UF TABLE (id_unidad_funcional INT, id_consorcio INT);
    DECLARE @GastoOrd TABLE (monto DECIMAL(12,2));
    DECLARE @GastoExt TABLE (monto DECIMAL(12,2));

    INSERT INTO @Expensas
    SELECT id_expensa, primer_vencimiento, segundo_vencimiento FROM ddbba.expensa;

    INSERT INTO @UF
    SELECT id_unidad_funcional, id_consorcio FROM ddbba.unidad_funcional;

    INSERT INTO @GastoOrd
    SELECT importe FROM ddbba.gastos_ordinarios;

    INSERT INTO @GastoExt
    SELECT importe_total FROM ddbba.gasto_extraordinario;

    IF NOT EXISTS (SELECT 1 FROM @Expensas) OR NOT EXISTS (SELECT 1 FROM @UF)
    BEGIN
        PRINT N' No hay datos suficientes en expensa o unidad_funcional.';
        RETURN;
    END;

 -- 2. Generar registros random

    WHILE @i <= @cantidad
    BEGIN
        -- Seleccionar expensa y UF válidos
        SELECT TOP 1 
            @id_expensa = id_expensa,
            @fecha_1er_vto = fecha_1er_vto,
            @fecha_2do_vto = fecha_2do_vto
        FROM @Expensas ORDER BY NEWID();

        SELECT TOP 1 
            @id_unidad_funcional = id_unidad_funcional,
            @id_consorcio = id_consorcio
        FROM @UF ORDER BY NEWID();

        -- Buscar fecha de pago (si existe)
        SELECT TOP 1 @fecha_pago = fecha_pago
        FROM ddbba.pago
        WHERE id_expensa = @id_expensa
          AND id_unidad_funcional = @id_unidad_funcional
          AND id_consorcio = @id_consorcio;

        IF @fecha_pago IS NULL
            SET @fecha_pago = CAST(GETDATE() AS DATE); -- sin pago: hoy

        -- Gastos ordinarios y extraordinarios
        SELECT TOP 1 @gastos_ordinarios = monto FROM @GastoOrd ORDER BY NEWID();
        SELECT TOP 1 @gastos_extraordinarios = monto FROM @GastoExt ORDER BY NEWID();

        -- Valor de la cuota
        SET @valor_cuota = @gastos_ordinarios + @gastos_extraordinarios;

        -- Interés por mora
        IF @fecha_pago < @fecha_1er_vto
            SET @interes_mora = 0.00;
        ELSE IF @fecha_pago BETWEEN @fecha_1er_vto AND @fecha_2do_vto
            SET @interes_mora = 0.02;
        ELSE
            SET @interes_mora = 0.05;

        -- Calcular deuda y total
        SET @deuda = @valor_cuota * @interes_mora;
        SET @monto_total = @valor_cuota + @deuda;

        -- Insertar en detalle
        INSERT INTO ddbba.detalle_expensas_por_uf (
            id_detalle,
            id_expensa,
            id_unidad_funcional,
            id_consorcio,
            gastos_ordinarios,
            gastos_extraordinarios,
            deuda,
            interes_mora,
            monto_total
        )
        VALUES (
            @i,
            @id_expensa,
            @id_unidad_funcional,
            @id_consorcio,
            @gastos_ordinarios,
            @gastos_extraordinarios,
            @deuda,
            @interes_mora * 100,  -- porcentaje
            @monto_total
        );

        SET @i += 1;
    END;

    PRINT N' Generación de detalle_expensas_por_uf finalizada correctamente.';
END;
GO
------------------------------------------------------------------------------------------
--Generar Estados financieros
CREATE OR ALTER PROCEDURE ddbba.sp_generar_estado_financiero
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Limpiar la tabla de estados anteriores
    DELETE FROM ddbba.estado_financiero;

    -- 2. Insertar los nuevos estados financieros de forma masiva
    INSERT INTO ddbba.estado_financiero (
        id_expensa,
        saldo_anterior,
        ingresos_en_termino,
        ingresos_adelantados,
        ingresos_adeudados,
        egresos_del_mes,
        saldo_cierre
    )
    SELECT
        e.id_expensa,

        -- Saldo anterior = 10% de los egresos del mes
        x.egresos_del_mes * 0.1 AS saldo_anterior,

        -- Ingresos en término
        ISNULL(SUM(CASE 
            WHEN p.fecha_pago BETWEEN e.primer_vencimiento AND e.segundo_vencimiento THEN p.monto 
            ELSE 0 END), 0) AS ingresos_en_termino,

        -- Ingresos adelantados
        ISNULL(SUM(CASE 
            WHEN p.fecha_pago < e.primer_vencimiento THEN p.monto 
            ELSE 0 END), 0) AS ingresos_adelantados,

        -- Ingresos adeudados = total expensas - total pagos
        CASE 
            WHEN ISNULL(SUM(de.monto_total),0) - ISNULL(SUM(p.monto),0) < 0 THEN 0
            ELSE ISNULL(SUM(de.monto_total),0) - ISNULL(SUM(p.monto),0)
        END AS ingresos_adeudados,

        -- Egresos del mes
        x.egresos_del_mes,

        -- Saldo cierre = saldo anterior + ingresos - egresos
        (x.egresos_del_mes * 0.1)
            + ISNULL(SUM(CASE WHEN p.fecha_pago BETWEEN e.primer_vencimiento AND e.segundo_vencimiento THEN p.monto ELSE 0 END), 0)
            + ISNULL(SUM(CASE WHEN p.fecha_pago < e.primer_vencimiento THEN p.monto ELSE 0 END), 0)
            - x.egresos_del_mes
            - CASE 
                WHEN ISNULL(SUM(de.monto_total),0) - ISNULL(SUM(p.monto),0) < 0 THEN 0
                ELSE ISNULL(SUM(de.monto_total),0) - ISNULL(SUM(p.monto),0)
              END AS saldo_cierre

    FROM ddbba.expensa e
    LEFT JOIN (
        SELECT id_expensa, SUM(importe) AS monto FROM ddbba.gastos_ordinarios GROUP BY id_expensa
    ) AS goo ON e.id_expensa = goo.id_expensa
    LEFT JOIN (
        SELECT id_expensa, SUM(importe_total) AS monto FROM ddbba.gasto_extraordinario GROUP BY id_expensa
    ) AS ge ON e.id_expensa = ge.id_expensa
    LEFT JOIN ddbba.pago AS p ON e.id_expensa = p.id_expensa
    LEFT JOIN ddbba.detalle_expensas_por_uf AS de ON e.id_expensa = de.id_expensa

    CROSS APPLY (
        SELECT ISNULL(goo.monto,0) + ISNULL(ge.monto,0) AS egresos_del_mes
    ) AS x

    GROUP BY 
        e.id_expensa,
        e.primer_vencimiento,
        e.segundo_vencimiento,
        x.egresos_del_mes;

    PRINT N'--- Generación de estado financiero finalizada correctamente ---';
END;
GO