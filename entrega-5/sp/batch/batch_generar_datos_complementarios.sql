/*Generacion da los datos faltantes*/


--------------------------------------------------------------
-- Generar Cuotas Random
CREATE OR ALTER PROCEDURE ddbba.sp_GenerarCuotas
AS
BEGIN
    INSERT INTO ddbba.cuotas (nro_cuota, id_gasto_extraordinario)
    SELECT 
        n.nro,
        ge.id_gasto_extraordinario
    FROM ddbba.gasto_extraordinario ge
    CROSS APPLY (
        SELECT TOP (ge.total_cuotas) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS nro
        FROM sys.all_objects
    ) n
    WHERE NOT EXISTS (
        SELECT 1 FROM ddbba.cuotas c
        WHERE c.id_gasto_extraordinario = ge.id_gasto_extraordinario
          AND c.nro_cuota = n.nro
    );
END

----------------------------------------------------------------------------------------------------
-- Generar Envíos de Expensas Random
CREATE OR ALTER PROCEDURE ddbba.sp_GenerarEnviosExpensas
    @CantidadRegistros INT 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @i INT = 1;
    DECLARE @IdExpensa INT;
    DECLARE @IdUF INT;
    DECLARE @IdConsorcio INT;
    DECLARE @IdTipo INT;
    DECLARE @TipoDoc VARCHAR(10);
    DECLARE @Documento BIGINT;
    DECLARE @FechaEnvio DATE;
    
    WHILE @i <= @CantidadRegistros
    BEGIN
        -- Seleccionar IDs random de tablas relacionadas
        SET @IdExpensa = (SELECT TOP 1 id_expensa FROM ddbba.expensa ORDER BY NEWID());
        SET @IdTipo = (SELECT TOP 1 id_tipo_envio FROM ddbba.tipo_envio ORDER BY NEWID());
        SELECT TOP 1 
			  @IdUF = id_unidad_funcional,
			  @IdConsorcio = id_consorcio
	   FROM ddbba.unidad_funcional 
       ORDER BY NEWID();
        
        -- Obtener un documento random de la tabla persona
        SELECT TOP 1 
            @TipoDoc = tipo_documento,
            @Documento = nro_documento
        FROM ddbba.persona
        ORDER BY NEWID();
        
        -- Generar fecha random en los últimos 365 días
        SET @FechaEnvio = DATEADD(DAY, -FLOOR(RAND() * 365), GETDATE());
        
        INSERT INTO ddbba.envio_expensa (
            id_expensa, 
            id_unidad_funcional, 
            id_consorcio,
            id_tipo_envio, 
            destinatario_nro_documento, 
            destinatario_tipo_documento, 
            fecha_envio
        )
        VALUES (
            @IdExpensa, 
            @IdUF, 
            @IdConsorcio,
            @IdTipo, 
            @Documento, 
            @TipoDoc, 
            @FechaEnvio
        );
        
        SET @i = @i + 1;
    END
    
    PRINT 'Se generaron ' + CAST(@CantidadRegistros AS VARCHAR) + ' envíos de expensas random.';
END
GO


----------------------------------------------------------------------------------------
--Generar Gastos Extraordinarios Random

CREATE OR ALTER PROCEDURE ddbba.sp_GenerarGastosExtraordinarios
    @CantidadRegistros INT 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @i INT = 1;
    DECLARE @IdExpensa INT;
    DECLARE @Detalle VARCHAR(200);
    DECLARE @TotalCuotas INT;
    DECLARE @PagoEnCuotas BIT;
    DECLARE @ImporteTotal DECIMAL(18,2);
    
    DECLARE @Detalles TABLE (Descripcion VARCHAR(200));
    INSERT INTO @Detalles VALUES 
        ('Pintura de fachada'),
        ('Reparación de ascensor'),
        ('Cambio de bomba de agua'),
        ('Arreglo de portón eléctrico'),
        ('Impermeabilización de terraza'),
        ('Instalación de cámaras de seguridad'),
        ('Reparación de tanque de agua'),
        ('Cambio de medidores'),
        ('Refacción de hall de entrada'),
        ('Arreglo de instalación eléctrica');
    
    WHILE @i <= @CantidadRegistros
    BEGIN
        SET @IdExpensa = (SELECT TOP 1 id_expensa FROM ddbba.expensa ORDER BY NEWID());
        SET @Detalle = (SELECT TOP 1 Descripcion FROM @Detalles ORDER BY NEWID());
        SET @PagoEnCuotas = CASE WHEN RAND() > 0.5 THEN 1 ELSE 0 END;
        SET @TotalCuotas = CASE WHEN @PagoEnCuotas = 1 THEN FLOOR(RAND() * 11) + 2 ELSE 1 END;
        SET @ImporteTotal = ROUND(RAND() * 500000 + 50000, 2);
        
        INSERT INTO ddbba.gasto_extraordinario (id_expensa, detalle, total_cuotas, 
                                           pago_en_cuotas, importe_total)
        VALUES (@IdExpensa, @Detalle, @TotalCuotas, @PagoEnCuotas, @ImporteTotal);
        
        SET @i = @i + 1;
    END
    
    PRINT 'Se generaron ' + CAST(@CantidadRegistros AS VARCHAR) + ' gastos extraordinarios random.';
END
GO

--------------------------------------------------------------------------------------
--Generar Pagos Random

CREATE OR ALTER PROCEDURE ddbba.sp_GenerarPagos
    @CantidadRegistros INT 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @i INT = 1;
    DECLARE @IdPago INT;
    DECLARE @IdUF INT;
    DECLARE @IdConsorcio INT;
    DECLARE @IdExpensa INT;
    DECLARE @Fecha DATE;
    DECLARE @Monto DECIMAL(18,2);
    DECLARE @CbuOrigen VARCHAR(22);
    DECLARE @Estado VARCHAR(20);
    
    -- Obtener el último id_pago existente
    SELECT @IdPago = ISNULL(MAX(id_pago), 0) FROM ddbba.pago;
    
    WHILE @i <= @CantidadRegistros
    BEGIN
        -- Incrementar el id_pago
        SET @IdPago = @IdPago + 1;
        
        -- Seleccionar unidad funcional Y su consorcio juntos
        SELECT TOP 1 
            @IdUF = id_unidad_funcional,
            @IdConsorcio = id_consorcio
        FROM ddbba.unidad_funcional 
        ORDER BY NEWID();
        
        SET @IdExpensa = (SELECT TOP 1 id_expensa FROM ddbba.expensa ORDER BY NEWID());
        SET @Fecha = DATEADD(DAY, -FLOOR(RAND() * 180), GETDATE());
        SET @Monto = ROUND(RAND() * 100000 + 5000, 2);
        
        -- Obtener un CBU real de la tabla persona
        SET @CbuOrigen = (SELECT TOP 1 cbu FROM ddbba.persona WHERE cbu IS NOT NULL ORDER BY NEWID());
        
        -- Si no hay CBUs en persona, generar uno random
        IF @CbuOrigen IS NULL
        BEGIN
            SET @CbuOrigen = '';
            DECLARE @j INT = 1;
            WHILE @j <= 22
            BEGIN
                SET @CbuOrigen = @CbuOrigen + CAST(FLOOR(RAND() * 10) AS VARCHAR(1));
                SET @j = @j + 1;
            END
        END
        
        -- Estado random
        SET @Estado = CASE FLOOR(RAND() * 3)
            WHEN 0 THEN 'Aprobado'
            WHEN 1 THEN 'Pendiente'
            ELSE 'Rechazado'
        END;
        
        INSERT INTO ddbba.pago (
            id_pago,
            id_unidad_funcional,
            id_consorcio,
            id_expensa,
            fecha_pago,
            monto,
            cbu_origen,
            estado
        )
        VALUES (
            @IdPago,
            @IdUF,
            @IdConsorcio,
            @IdExpensa,
            @Fecha,
            @Monto,
            @CbuOrigen,
            @Estado
        );
        
        SET @i = @i + 1;
    END
    
    PRINT 'Se generaron ' + CAST(@CantidadRegistros AS VARCHAR) + ' pagos random.';
END
GO


----------------------------------------------------------------
--Generar Tipos de Envío Random

CREATE OR ALTER PROCEDURE ddbba.sp_GenerarTiposEnvioRandom
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Limpiar tabla si existe datos
    IF EXISTS (SELECT 1 FROM ddbba.tipo_envio)
    BEGIN
        PRINT 'La tabla tipo_envio ya contiene datos. No se insertarán duplicados.';
        RETURN;
    END
    
    INSERT INTO ddbba.tipo_envio (detalle) VALUES
        ('Email'),
        ('WhatsApp');
    
    PRINT 'Se generaron los tipos de envío predefinidos.';
END
GO
---------------------------------------------------------------------------
-- Generar vencimientos de expensas

CREATE OR ALTER PROCEDURE ddbba.sp_generar_vencimientos_expensas
    @dias_primer_vencimiento INT ,  -- Días después de emisión para 1er vencimiento
    @dias_segundo_vencimiento INT   -- Días después de emisión para 2do vencimiento
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Actualizar solo los registros que tienen fecha_emision pero no tienen vencimientos
        UPDATE ddbba.expensa
        SET 
            primer_vencimiento = DATEADD(DAY, @dias_primer_vencimiento, fecha_emision),
            segundo_vencimiento = DATEADD(DAY, @dias_segundo_vencimiento, fecha_emision)
        WHERE 
            fecha_emision IS NOT NULL
            AND (primer_vencimiento IS NULL OR segundo_vencimiento IS NULL);
        
        -- Retornar cantidad de registros actualizados
        DECLARE @registros_actualizados INT = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Mensaje de resultado
        SELECT 
            @registros_actualizados AS RegistrosActualizados,
            'Vencimientos generados correctamente' AS Mensaje;
            
    END TRY
    BEGIN CATCH
        -- En caso de error, hacer rollback
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Retornar información del error
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje,
            ERROR_LINE() AS ErrorLinea;
    END CATCH
END;
GO
--------------------------------------------------------
-- Generar detalle de expensas por uf
CREATE OR ALTER PROCEDURE ddbba.sp_generar_detalle_expensas_por_uf
    @cantidad INT 
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


-------------------------------------------------

-- Ejecución de todos los SP

EXEC ddbba.sp_GenerarTiposEnvioRandom;
EXEC ddbba.sp_GenerarEnviosExpensas @CantidadRegistros = 10;
EXEC ddbba.sp_GenerarEstadosFinancieros @CantidadRegistros = 10;
EXEC ddbba.sp_GenerarGastosExtraordinarios @CantidadRegistros = 10;
EXEC ddbba.sp_GenerarCuotas ;
EXEC ddbba.sp_GenerarPagos @CantidadRegistros = 10;
EXEC ddbba.sp_generar_vencimientos_expensas @dias_primer_vencimiento=15,@dias_Segundo_vencimiento=20
EXEC ddbba.sp_generar_detalle_expensas_por_uf @cantidad=10
EXEC ddbba.sp_generar_estado_financiero


