/*ENUNCIADO:CREACION DE PRUEBAS
COMISION:02-5600 
CURSO:3641
NUMERO DE GRUPO : 01
MATERIA: BASE DE DATOS APLICADA
INTEGRANTES:
Bonachera Ornella — 46119546 
Benitez Jimena — 46097948 
Arcón Wogelman, Nazareno-44792096
Perez, Olivia Constanza — 46641730
Guardia Gabriel — 42364065 
Arriola Santiago — 41743980 
*/

USE Com5600_Grupo01;
GO

--TEST 01 DESPUES DE EJECUTAR LOS PASOS 00-01-02-03
--PARA EJECUTAR TODA LA IMPORTACION DE ARCHIVOS
exec ddbba.sp_importar_archivos

--TEST PARA COMPROBAR QUE TODAS LAS TABLAS SE CARGARON CORRECTAMENTE
select * from ddbba.unidad_funcional
select * from ddbba.consorcio
select * from ddbba.persona
select * from ddbba.rol
select * from ddbba.pago
select * from ddbba.expensa
select * from ddbba.tipo_gasto
select * from ddbba.gastos_ordinarios
select * from ddbba.proveedores
delete from ddbba.rol

---------------------------------------------------------------------------------------------------------
--TEST 02 DESPUES DE EJECUTAR EL PASO 04

--PARA EJECUTAR TODOS LOS SP DE DATOS RANDOM 
exec ddbba.sp_crear_datos_adicionales


--TEST PARA COMPROBAR QUE SE GENERARON TODOS LOS DATOS
--Envios
select * from ddbba.tipo_envio
select * from ddbba.envio_expensa
--Estado financiero
select* from ddbba.estado_financiero
--Gastos
select* from ddbba.gasto_extraordinario
--Cuotas
select* from ddbba.cuotas
select* from ddbba.gasto_extraordinario
--Pagos
select* from ddbba.pago
--fecha de vencimientos
select* from ddbba.expensa
--expensa x uf
select* from ddbba.detalle_expensas_por_uf


--------------------------------------------------------------------------
--TEST 03 DESPUES DE EJECUTAR EL PASO 05

--REPORTE 1
exec ddbba.sp_reporte_1
select sum(p.monto) from ddbba.pago p

--REPORTE 2
exec ddbba.sp_reporte_2 @min= 74000
exec ddbba.sp_reporte_2  @min=70000, @max=80000
exec ddbba.sp_reporte_2 

--REPORTE 3
--1. Sin parametros
exec ddbba.sp_reporte_3;

--2. Con parametros de fecha
exec ddbba.sp_reporte_3 
    @FechaDesde = '2025-01-01',
    @FechaHasta = '2025-04-30';

--3. Con ID de consorcio
exec ddbba.sp_reporte_3 
    @IdConsorcio = 2


--REPORTE 4
EXEC ddbba.sp_reporte_4;-- sin parametros de entrada
EXEC ddbba.sp_reporte_4 @id_consorcio = 5; --mandadole un consorcio
EXEC ddbba.sp_reporte_4 @AnioDesde = 2025, @AnioHasta = 2025; --mandadole años
EXEC ddbba.sp_reporte_4 @id_consorcio = 1, @AnioDesde = 2025, @AnioHasta = 2025;--mandadole todos los parametos

--REPORTE 5
EXEC ddbba.sp_reporte_5;

--REPORTE 6
--  Todos los pagos de todas las UF
EXEC ddbba.sp_reporte_6;

-- Solo pagos del UF 1
EXEC ddbba.sp_reporte_6 @id_unidad_funcional = 1;

-- Pagos entre enero y marzo de 2025
EXEC ddbba.sp_reporte_6 @fecha_desde = '2025-01-01', @fecha_hasta = '2025-03-31';

-- Pagos del UF 2 entre febrero y abril
EXEC ddbba.sp_reporte_6 @id_unidad_funcional = 2, @fecha_desde = '2025-02-01', @fecha_hasta = '2025-04-30';

----------------------------------------------------------------------------------------------------------
--TEST 04 DESPUES DE EJEUTAR EL PASO DE SEGURIDAD
--PARA VER LAS TABLAS CIFRADAS
SELECT *
FROM ddbba.persona
SELECT *
FROM ddbba.unidad_funcional
SELECT *
FROM ddbba.pago

--PARA VER LAS TABLAS DECIFRADAS
select * from ddbba.vw_persona
select * from ddbba.vw_pago
select * from ddbba.vw_uf

--TEST PARA LOS TRIGGERS
INSERT INTO ddbba.persona (nombre,tipo_documento,nro_documento, mail, telefono, cbu)
VALUES ('Jimena Benitez', 'DNI','46097948','jime@example.com', '1122334455', '0170123400000000000001');
select * from ddbba.persona

INSERT INTO ddbba.pago (id_pago,id_consorcio, id_expensa, id_unidad_funcional, fecha_pago, monto, cbu_origen, estado)
VALUES ( 102,1,1, 1, GETDATE(), 55000, '0170123400000000000002', 'Aprobado');
 select * from ddbba.pago

INSERT INTO ddbba.unidad_funcional (id_unidad_funcional,id_consorcio, metros_cuadrados, piso, departamento, cochera, baulera, coeficiente, saldo_anterior, cbu, prorrateo)
VALUES (40,1, 75, 3, 'B', 1, 0, 0.8, 0, '0170123400000000000003', 0.8);
SELECT * FROM ddbba.unidad_funcional
