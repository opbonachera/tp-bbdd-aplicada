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
    @CantidadRegistros INT = 10
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
------------------------------------------------------------------------------------------
-- Generar Estados Financieros Random
CREATE OR ALTER PROCEDURE ddbba.sp_GenerarEstadosFinancieros
    @CantidadRegistros INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @i INT = 1;
    DECLARE @IdExpensa INT;
    DECLARE @SaldoAnterior DECIMAL(18,2);
    DECLARE @IngresosTermino DECIMAL(18,2);
    DECLARE @IngresosAdelantados DECIMAL(18,2);
    DECLARE @IngresosAdeudados DECIMAL(18,2);
    DECLARE @EgresosMes DECIMAL(18,2);
    DECLARE @SaldoCierre DECIMAL(18,2);
    DECLARE @ExpensasDisponibles INT;
    
    -- Verificar cuántas expensas sin estado financiero hay disponibles
    SELECT @ExpensasDisponibles = COUNT(*)
    FROM ddbba.expensa e
    WHERE NOT EXISTS (
        SELECT 1 
        FROM ddbba.estado_financiero ef 
        WHERE ef.id_expensa = e.id_expensa
    );
    
    IF @ExpensasDisponibles = 0
    BEGIN
        PRINT 'No hay expensas disponibles sin estado financiero.';
        RETURN;
    END
    
    IF @CantidadRegistros > @ExpensasDisponibles
    BEGIN
        PRINT 'Solo hay ' + CAST(@ExpensasDisponibles AS VARCHAR) + ' expensas disponibles. Se generarán ' + CAST(@ExpensasDisponibles AS VARCHAR) + ' estados financieros.';
        SET @CantidadRegistros = @ExpensasDisponibles;
    END
    
    WHILE @i <= @CantidadRegistros
    BEGIN
        -- Seleccionar una expensa que NO tenga estado financiero
        SET @IdExpensa = (
            SELECT TOP 1 e.id_expensa 
            FROM ddbba.expensa e
            WHERE NOT EXISTS (
                SELECT 1 
                FROM ddbba.estado_financiero ef 
                WHERE ef.id_expensa = e.id_expensa
            )
            ORDER BY NEWID()
        );
        
        -- Generar montos random entre -50000 y 200000
        SET @SaldoAnterior = ROUND(RAND() * 100000 - 50000, 2);
        SET @IngresosTermino = ROUND(RAND() * 150000, 2);
        SET @IngresosAdelantados = ROUND(RAND() * 50000, 2);
        SET @IngresosAdeudados = ROUND(RAND() * 80000, 2);
        SET @EgresosMes = ROUND(RAND() * 120000, 2);
        
        -- Calcular saldo de cierre
        SET @SaldoCierre = @SaldoAnterior + @IngresosTermino + @IngresosAdelantados - @EgresosMes;
        
        INSERT INTO ddbba.estado_financiero (
            id_expensa, 
            saldo_anterior, 
            ingresos_en_termino, 
            ingresos_adelantados, 
            ingresos_adeudados, 
            egresos_del_mes, 
            saldo_cierre
        )
        VALUES (
            @IdExpensa, 
            @SaldoAnterior, 
            @IngresosTermino, 
            @IngresosAdelantados,
            @IngresosAdeudados, 
            @EgresosMes, 
            @SaldoCierre
        );
        
        SET @i = @i + 1;
    END
    
    PRINT 'Se generaron ' + CAST(@CantidadRegistros AS VARCHAR) + ' estados financieros random.';
END
GO

----------------------------------------------------------------------------------------
--Generar Gastos Extraordinarios Random

CREATE OR ALTER PROCEDURE ddbba.sp_GenerarGastosExtraordinarios
    @CantidadRegistros INT = 10
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
    @CantidadRegistros INT = 10
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

CREATE OR ALTER PROCEDURE ddbba.sp_GenerarTiposEnvio
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
    @dias_primer_vencimiento INT = 15,  -- Días después de emisión para 1er vencimiento
    @dias_segundo_vencimiento INT = 20   -- Días después de emisión para 2do vencimiento
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
-------------------------------------------------
--este es el orden con el que se tiene que ejecutar casa SP
-- Ejecución de todos los SP

EXEC ddbba.sp_GenerarTiposEnvio;
EXEC ddbba.sp_GenerarEnviosExpensas @CantidadRegistros = 10;
EXEC ddbba.sp_GenerarEstadosFinancieros @CantidadRegistros = 10;
EXEC ddbba.sp_GenerarGastosExtraordinarios @CantidadRegistros = 10;
EXEC ddbba.sp_GenerarCuotas ;
EXEC ddbba.sp_GenerarPagos @CantidadRegistros = 10;
EXEC ddbba.sp_generar_vencimientos_expensas 
EXEC ddbba.sp_generar_detalle_expensas_por_uf
EXEC ddbba.sp_generar_estado_financiero

