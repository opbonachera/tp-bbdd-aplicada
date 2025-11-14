/*ENUNCIADO:CREACION DE SP NECESARIOS PARA LA IMPORTACION TODOS LOS ARCHIVOS 
Y LOS COMANDOS PARA MOSTAR LA CORRECTA IMPORTACION
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



-------------------------------------------------------
-- IMPORTA TODOS LOS ARCHIVOS
-------------------------------------------------------
create or alter procedure ddbba.sp_importar_archivos
as
begin	
	exec ddbba.sp_importar_consorcios @ruta_archivo = 'C:\Archivos para el tp\datos varios.xlsx'
	exec ddbba.sp_importar_proveedores @ruta_archivo ='C:\Archivos para el tp\datos varios.xlsx' 
	exec ddbba.sp_importar_pagos @ruta_archivo = 'C:\Archivos para el tp\pagos_consorcios.csv'
	exec ddbba.sp_importar_uf_por_consorcios @ruta_archivo = 'C:\Archivos para el tp\UF por consorcio.txt' 
	exec ddbba.sp_importar_inquilinos_propietarios @ruta_archivo = 'C:\Archivos para el tp\Inquilino-propietarios-datos.csv'
	exec ddbba.sp_importar_servicios @ruta_archivo = 'C:\Archivos para el tp\Servicios.Servicios.json', @anio=2025
    exec ddbba.sp_relacionar_inquilinos_uf @ruta_archivo = 'C:\Archivos para el tp\Inquilino-propietarios-UF.csv'
	exec ddbba.sp_relacionar_pagos
	exec ddbba.sp_actualizar_prorrateo
end

exec ddbba.sp_importar_archivos



select * from ddbba.unidad_funcional
select * from ddbba.consorcio
select * from ddbba.persona
select * from ddbba.rol
select * from ddbba.pago
select * from ddbba.expensa
select * from ddbba.tipo_gasto
select * from ddbba.gastos_ordinarios
select * from ddbba.proveedores
 delete from ddbba.pago