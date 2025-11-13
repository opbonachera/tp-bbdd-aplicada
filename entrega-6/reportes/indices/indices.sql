-- ======================================
-- ÍNDICES PARA OPTIMIZAR sp_reporte_1
-- ======================================

-- 1️⃣ Pago: filtro por año y join con expensa
CREATE INDEX IX_pago_fecha_expensa
ON ddbba.pago (fecha_pago, id_expensa)
INCLUDE (monto);

-- 2️⃣ Expensa: join con pago y filtro por consorcio
CREATE INDEX IX_expensa_consorcio
ON ddbba.expensa (id_expensa, id_consorcio);

-- 3️⃣ Gastos ordinarios: join por expensa
CREATE INDEX IX_gastos_ordinarios_expensa
ON ddbba.gastos_ordinarios (id_expensa, id_gasto_ordinario);

-- 4️⃣ Gasto extraordinario: join por expensa
CREATE INDEX IX_gasto_extraordinario_expensa
ON ddbba.gasto_extraordinario (id_expensa, id_gasto_extraordinario);


-- ==================================================
-- ÍNDICES PARA OPTIMIZAR ddbba.sp_reporte_2
-- ==================================================

-- 1️⃣ Índice principal sobre pago:
--    mejora los filtros por fecha y joins por unidad funcional.
CREATE INDEX IX_pago_fecha_unidad_monto
ON ddbba.pago (fecha_pago, id_unidad_funcional)
INCLUDE (monto);

-- 2️⃣ Índice sobre unidad_funcional:
--    mejora el join y la búsqueda de departamentos únicos.
CREATE INDEX IX_unidad_funcional_departamento
ON ddbba.unidad_funcional (id_unidad_funcional, departamento);


-- ==================================================
-- ÍNDICES PARA OPTIMIZAR ddbba.sp_reporte_3
-- ==================================================

-- Índice para mejorar filtros y joins en expensa
CREATE INDEX IX_expensa_consorcio_fecha 
ON ddbba.expensa (id_consorcio, fecha_emision, id_expensa);

-- Índices para acelerar los joins y SUM en gastos
CREATE INDEX IX_gastos_ordinarios_expensa 
ON ddbba.gastos_ordinarios (id_expensa, importe);

CREATE INDEX IX_gasto_extraordinario_expensa 
ON ddbba.gasto_extraordinario (id_expensa, importe_total);


-- ==================================================
-- ÍNDICES PARA OPTIMIZAR ddbba.sp_reporte_6
-- ==================================================

-- Índice para optimizar el filtrado y orden de los pagos por UF, ID expensa y fecha
CREATE INDEX IX_pago_consorcio_uf_fecha
ON ddbba.pago (id_unidad_funcional, id_expensa, fecha_pago);
GO 