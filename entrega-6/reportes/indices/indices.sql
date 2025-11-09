--Indices para el reporte 3

-- Índice para mejorar filtros y joins en expensa
CREATE INDEX IX_expensa_consorcio_fecha 
ON ddbba.expensa (id_consorcio, fecha_emision, id_expensa);

-- Índices para acelerar los joins y SUM en gastos
CREATE INDEX IX_gastos_ordinarios_expensa 
ON ddbba.gastos_ordinarios (id_expensa, importe);

CREATE INDEX IX_gasto_extraordinario_expensa 
ON ddbba.gasto_extraordinario (id_expensa, importe_total);
