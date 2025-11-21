/*---------------------------------------------------------
 Materia:     Base de datos aplicada. 
 Grupo:       1
 Comision:    5600
 Fecha:       2025-01-01
 Descripcion: Creacion de índices para mejorar el rendimiento de los reportes.
 Integrantes: Arcón Wogelman, Nazareno — 44792096
              Arriola Santiago — 41743980 
              Bonachera Ornella — 46119546
              Benitez Jimena — 46097948
              Guardia Gabriel — 42364065
              Perez, Olivia Constanza — 46641730
----------------------------------------------------------*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> INICIO DEL SCRIPT  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
USE Com5600_Grupo01;
GO
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CREACION DE INDICES PARA OPTIMIZACION DE CONSULTAS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/

-- 1 Índice principal sobre pago:
--    mejora los filtros por fecha y joins por unidad funcional.
CREATE INDEX IX_pago_fecha_unidad_monto
ON finanzas.pago (fecha_pago, id_unidad_funcional)
INCLUDE (monto);

-- 2 Índice sobre unidad_funcional:
--    mejora el join y la búsqueda de departamentos únicos.
CREATE INDEX IX_unidad_funcional_departamento
ON consorcios.unidad_funcional (id_unidad_funcional, departamento);

-- ==================================================
-- ÍNDICES PARA OPTIMIZAR ddbba.sp_reporte_3
-- ==================================================

-- Índice para mejorar filtros y joins en expensa
CREATE INDEX IX_expensa_consorcio_fecha 
ON finanzas.expensa (id_consorcio, fecha_emision, id_expensa);

-- Índices para acelerar los joins y SUM en gastos
CREATE INDEX IX_gastos_ordinarios_expensa 
ON finanzas.gastos_ordinarios (id_expensa, importe);


-- =====================================================
-- ÍNDICES PARA ddbba.sp_reporte_4
-- =====================================================

-- 3 Índice sobre GASTO_EXTRAORDINARIO:
CREATE INDEX IX_gasto_extraordinario_expensa
ON finanzas.gasto_extraordinario (id_expensa)
INCLUDE (importe_total);

-- 4 Índice sobre PAGO:
-- Mejora el filtro por consorcio, fecha y estado (Aprobado),
-- además de las funciones YEAR() y MONTH() usadas en los agrupamientos.
CREATE INDEX IX_pago_consorcio_fecha_estado
ON finanzas.pago (id_consorcio, fecha_pago, estado)
INCLUDE (monto, id_unidad_funcional);

-- =====================================================
-- ÍNDICES RECOMENDADOS PARA ddbba.sp_reporte_5
-- =====================================================

-- Mejora los JOINS con unidad funcional y expensa, también optimiza la función SUM()
CREATE INDEX IX_detalle_expensas_por_uf_unidad_consorcio_expensa
ON finanzas.detalle_expensas_por_uf (id_unidad_funcional, id_consorcio, id_expensa)
INCLUDE (deuda);

-- Optimiza filtros where y JOINs de persona y unidad funcional
CREATE INDEX IX_rol_propietario
ON personas.rol (nombre_rol, nro_documento, tipo_documento, id_unidad_funcional, id_consorcio);

-- Optimiza JOINs con rol y id expensa por unidad funcional
CREATE INDEX IX_unidad_funcional_consorcio
ON consorcios.unidad_funcional (id_unidad_funcional, id_consorcio);

-- Optimiza JOIN con rol
CREATE INDEX IX_persona_documento
ON personas.persona (nro_documento, tipo_documento);

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FINALIZA CREACION DE INDICES PARA OPTIMIZACION DE CONSULTAS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DEL SCRIPT  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
