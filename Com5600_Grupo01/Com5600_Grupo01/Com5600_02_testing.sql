/*---------------------------------------------------------
 Materia:     Base de datos aplicada. 
 Grupo:       1
 Comision:    5600
 Fecha:       2025-01-01
 Descripcion: Ejecución de queries de testing.
              NOTA: A diferencia del resto de los scripts este
              archivo NO crea objetos sino que selecciona datos y ejecuta procedimientos.
              Se recomienda ejecutar las queries en el órden indicado del script. 
 Integrantes: Bonachera Ornella — 46119546
              Benitez Jimena — 46097948
              Arcón Wogelman, Nazareno — 44792096
              Perez, Olivia Constanza — 46641730
              Guardia Gabriel — 42364065
              Arriola Santiago — 41743980 
----------------------------------------------------------*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> EJECUCION DE PRUEBAS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
USE "Com5600_Grupo01"
GO
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> IMPORTACION DE ARCHIVOS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*--- PASO 1: ver las tablas y las funciones creadas ---*/
SELECT 
    o.name AS objeto,
    s.name AS schema_name,
    o.type_desc AS tipo,
    o.create_date
FROM sys.objects o
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE s.name IN ('ddbba', 'datos', 'personas', 'finanzas', 'gestion')
  AND o.type IN ('U', 'FN', 'IF', 'TF')  -- U = tablas
ORDER BY o.type_desc, o.name;

/*--- PASO 2: verificar que las tablas se encuentran vacías (por conveniencia solo tabla de persona y consorcios)---*/
select * from personas.persona
go

select * from consorcios.consorcio
go

/* --- PASO 3: Ejecutar el procedimiento que importa todos los archivos ---*/
exec utils.sp_importar_archivos
go

select * from finanzas.pago
exec consorcios.sp_importar_consorcios @ruta_archivo = 'C:\Archivos para el tp\datos varios.xlsx'
exec personas.sp_importar_proveedores @ruta_archivo ='C:\Archivos para el tp\datos varios.xlsx' 
exec finanzas.sp_importar_pagos @ruta_archivo = 'C:\Archivos para el tp\pagos_consorcios.csv'
exec consorcios.sp_importar_uf_por_consorcios @ruta_archivo = 'C:\Archivos para el tp\UF por consorcio.txt' 
exec personas.sp_importar_inquilinos_propietarios @ruta_archivo = 'C:\Archivos para el tp\Inquilino-propietarios-datos.csv'
exec finanzas.sp_importar_servicios @ruta_archivo = 'C:\Archivos para el tp\Servicios.Servicios.json', @anio=2025
exec personas.sp_relacionar_inquilinos_uf @ruta_archivo = 'C:\Archivos para el tp\Inquilino-propietarios-UF.csv'
exec finanzas.sp_relacionar_pagos
exec consorcios.sp_actualizar_prorrateo
go

/*--- PASO 4: Seleccionar de las tablas para verificar la correcta importación de los archivos ---*/
select * from consorcios.unidad_funcional
select * from consorcios.consorcio
select * from personas.persona
select * from personas.rol
select * from finanzas.pago
select * from finanzas.expensa
select * from finanzas.tipo_gasto
select * from finanzas.gasto_ordinario
select * from personas.proveedor
go

/* --- PASO 5: Crear datos adicionales ---*/
exec utils.sp_crear_datos_adicionales

/* --- PASO 6: Seleccionar de las tablas en cuestion para verificar la correcta insercion de los datos---*/
select * from gestion.tipo_envio
select * from gestion.envio_expensa
select * from finanzas.estado_financiero
select * from finanzas.gasto_extraordinario
select * from finanzas.cuota
select * from finanzas.gasto_extraordinario
select * from finanzas.pago where estado not like 'asociado'
select * from finanzas.expensa
select * from finanzas.detalle_expensas_por_uf
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DE IMPORTACION DE ARCHIVOS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CREACION DE REPORTES  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/* --- PASO 1: Ejecutar reportes --- */

-- REPORTE 1: Flujo de caja semanal.
-- Parametros: rango de fechas - id del consorcio. 
exec datos.sp_reporte_1
exec datos.sp_reporte_1 @id_consorcio=5
exec datos.sp_reporte_1 @anio_desde=2024, @anio_hasta = 2026

-- REPORTE 2: Tabla cruzada con recaudacion por departamento.
exec datos.sp_reporte_2 @min= 74000, @max = 900000
exec datos.sp_reporte_2 @min= 74000
-- Resultado esperado: Sin resultados ya que no hay sumatorias comprendidas en ese rango. 
exec datos.sp_reporte_2  @min=70000, @max=80000
-- Resultado esperado: Sin resultados ya que no hay expensas expendidas para ese año. 
exec datos.sp_reporte_2 @anio=2024

--REPORTE 3: Cuadro cruzado con la información desagregada según su procedencia. 
-- Parametros: rango de fechas, id del consorcio.  

-- Sin parametros
exec datos.sp_reporte_3;
-- Con parametros de fecha
exec datos.sp_reporte_3 
    @fecha_desde = '2025-01-01',
    @fecha_hasta = '2025-04-30';

-- Con ID de consorcio
exec datos.sp_reporte_3 
    @id_consorcio = 2


-- REPORTE 4: Obtener 5 meses de mayores gastos y 5 de mayores ingresos.
-- Parametros: rango de años, id del consorcio

-- Sin parametros de entrada
EXEC datos.sp_reporte_4;
-- Mandadole un consorcio
EXEC datos.sp_reporte_4 @id_consorcio = 5; 
-- Mandadole años
EXEC datos.sp_reporte_4 @anio_desde = 2025, @AnioHasta = 2025; 
-- Mandadole todos los parametros
EXEC datos.sp_reporte_4 @id_consorcio = 1, @anio_desde = 2025, @AnioHasta = 2025;

--REPORTE 5: Obtener 3 propietarios mas morosos.
--Parametros: rango de fechas, id del consorcio
EXEC datos.sp_reporte_5;
EXEC datos.sp_reporte_5 @id_consorcio=2;

--REPORTE 6: Fechas de pago de expensas ordinarias y los dias que transcurrieron entre pago y pago.
--Parametros: id de la UF, rango de fechas. 
EXEC datos.sp_reporte_6;
-- Solo pagos del UF 1
EXEC datos.sp_reporte_6 @id_unidad_funcional = 1;
-- Pagos entre enero y marzo de 2025
EXEC datos.sp_reporte_6 @fecha_desde = '2025-01-01', @fecha_hasta = '2025-03-31';
-- Pagos del UF 2 entre febrero y abril
EXEC datos.sp_reporte_6 @id_unidad_funcional = 2, @fecha_desde = '2025-02-01', @fecha_hasta = '2025-04-30';

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DE EJECUCION DE REPORTES  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SEGURIDAD  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*--- PASO 1: verificar datos no cifrados ---*/
SELECT * FROM personas.persona
SELECT * FROM consorcios.unidad_funcional
SELECT * FROM finanzas.pago
go

/*--- PASO 2: Cifrar datos ---*/
exec seguridad.sp_alter_table
go 
exec seguridad.sp_cifrado_tablas
go

/*--- PASO 3: Verificar el cifrado de los datos ---*/
SELECT * FROM personas.persona
SELECT * FROM consorcios.unidad_funcional
SELECT * FROM finanzas.pago
go

/*--- PASO 4: Ejecutar las vistas que muestra los datos desencriptados ---*/
select * from seguridad.vw_persona -- Muestra todos los datos de la persona con el CBU, mail y telefono desencriptado
select * from seguridad.vw_pago -- Muestra los datos de pago con CBU desencriptado
select * from seguridad.vw_uf -- Muestra los datos de unidad funcional con CBU desencriptado
go

/*--- PASO 5: Verificar la función del trigger ---*/
INSERT INTO personas.persona (nombre,tipo_documento,nro_documento, mail, telefono, cbu)
VALUES ('Jimena Benitez', 'DNI','2228889','jime@example.com', '1122334455', '0170123400000000000001');
go
-- Se debe verificar que los datos de mail, numero y telefono se muestren encriptados

select * from personas.persona where nro_documento='2228889'
go

INSERT INTO finanzas.pago (id_pago,id_consorcio, id_expensa, id_unidad_funcional, fecha_pago, monto, cbu_origen, estado)
VALUES ( 102,1,1, 1, GETDATE(), 55000, '0170123400000000000002', 'Aprobado');
go 

select * from finanzas.pago where id_pago = 102
go 

INSERT INTO consorcios.unidad_funcional (id_unidad_funcional,id_consorcio, metros_cuadrados, piso, departamento, cochera, baulera, coeficiente, saldo_anterior, cbu, prorrateo)
VALUES (40,1, 75, 3, 'B', 1, 0, 0.8, 0, '0170123400000000000003', 0.8);
go

SELECT * FROM consorcios.unidad_funcional
go

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DE SEGURIDAD  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DE EJECUCION DE PRUEBAS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DEL SCRIPT  <<<<<<<<<<<<<<<<<<<<<<<<<<*/