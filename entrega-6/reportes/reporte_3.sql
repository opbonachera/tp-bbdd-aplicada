


CREATE OR ALTER PROCEDURE ddbba.sp_reporte_3
AS
BEGIN
    SET NOCOUNT ON;

--  Insertar datos para probar 
    -- =============================================
    -- TIPO_GASTO (5 registros)
    -- =============================================
    INSERT INTO ddbba.tipo_gasto (detalle)
    VALUES 
    ('Limpieza'),
    ('Mantenimiento de ascensor'),
    ('Luz y electricidad'),
    ('Agua corriente'),
    ('Administración');

    -- =============================================
    -- EXPENSA (5 registros)
    -- =============================================
    INSERT INTO ddbba.expensa (id_consorcio, fecha_emision, primer_vencimiento, segundo_vencimiento)
    VALUES
    (1, '2025-01-01', '2025-01-10', '2025-01-20'),
    (2, '2025-02-01', '2025-02-10', '2025-02-20'),
    (3, '2025-03-01', '2025-03-10', '2025-03-20'),
    (4, '2025-04-01', '2025-04-10', '2025-04-20'),
    (5, '2025-05-01', '2025-05-10', '2025-05-20');

    -- =============================================
    -- GASTOS_ORDINARIOS (5 registros)
    -- =============================================
    INSERT INTO ddbba.gastos_ordinarios (id_expensa, id_tipo_gasto, detalle, nro_factura, importe)
    VALUES
    (1, 1, 'Servicio de limpieza mensual', 'FAC-001', 35000.000),
    (2, 2, 'Mantenimiento preventivo ascensor', 'FAC-002', 55000.500),
    (3, 3, 'Factura de Edesur marzo', 'FAC-003', 22000.750),
    (4, 4, 'Consumo de agua abril', 'FAC-004', 18000.000),
    (5, 5, 'Honorarios administración mayo', 'FAC-005', 40000.250);

    -- =============================================
    -- GASTO_EXTRAORDINARIO (5 registros)
    -- =============================================
    INSERT INTO ddbba.gasto_extraordinario (id_expensa, detalle, total_cuotas, pago_en_cuotas, importe_total)
    VALUES
    (1, 'Reparación de fachada', 6, 1, 300000.000),
    (2, 'Cambio total de cañerías', 8, 1, 450000.000),
    (3, 'Instalación de cámaras de seguridad', 3, 1, 150000.000),
    (4, 'Reacondicionamiento del jardín', 1, 0, 80000.000),
    (5, 'Compra de generador eléctrico', 4, 1, 200000.000);
 
--  Visualizo tablas
    select * from ddbba.tipo_gasto
    select * from ddbba.expensa
    SELECT * from ddbba.gasto_extraordinario
    SELECT * from ddbba.gastos_ordinarios
    /*
      Este procedimiento presenta un cuadro cruzado (PIVOT)
      con la recaudación total desagregada según su procedencia
      (Ordinario, Extraordinario, etc.) y por período.
    */

    -- Verificamos que existan los datos
    IF OBJECT_ID('tempdb..##temp_recaudacion') IS NULL
    BEGIN
        RAISERROR('No se encontraron datos de recaudación. Ejecute primero el procedimiento de carga.', 16, 1);
        RETURN;
    END

    -- Cuadro cruzado
    SELECT 
        Periodo,
        ISNULL([Ordinario], 0) AS Ordinario,
        ISNULL([Extraordinario], 0) AS Extraordinario,
        ISNULL([Otros], 0) AS Otros,
        (ISNULL([Ordinario],0) + ISNULL([Extraordinario],0) + ISNULL([Otros],0)) AS Total
    FROM
    (
        SELECT 
            Periodo,
            Procedencia,
            SUM(Monto) AS TotalRecaudado
        FROM ##temp_recaudacion
        GROUP BY Periodo, Procedencia
    ) AS Fuente
    PIVOT
    (
        SUM(TotalRecaudado)
        FOR Procedencia IN ([Ordinario], [Extraordinario], [Otros])
    ) AS PivotTable
    ORDER BY Periodo;
END;

GO

exec ddbba.sp_reporte_3; 

 