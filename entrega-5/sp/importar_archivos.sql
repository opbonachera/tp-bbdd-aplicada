-------------------------------------------------------
-- IMPORTA TODOS LOS ARCHIVOS
-------------------------------------------------------
create or alter procedure ddbba.sp_importar_archivos
as
begin	
	exec ddbba.sp_importar_consorcios @NomArch = 'C:\Archivos para el TP\datos varios.xlsx'
	exec ddbba.sp_importar_pagos @ruta_archivo = 'C:\Archivos para el TP\pagos_consorcios.csv'
	exec ddbba.sp_importar_uf_por_consorcios @ruta_archivo =  'C:\Archivos para el TP\UF por consorcio.txt'
	exec ddbba.sp_importar_inquilinos_propietarios @ruta_archivo = 'C:\Archivos para el TP\Inquilino-propietarios-datos.csv'
	exec ddbba.sp_importar_servicios @ruta_archivo = 'C:\Archivos para el TP\Servicios.Servicios.json', @anio=2025
    exec ddbba.sp_relacionar_inquilinos_uf @ruta_archivo = 'C:\Archivos para el TP\Inquilino-propietarios-UF.csv'
	exec ddbba.sp_actualizar_prorrateo
	exec ddbba.sp_relacionar_pagos
end

exec ddbba.sp_importar_archivos

select * from ddbba.unidad_funcional
select * from ddbba.consorcio
select * from ddbba.persona
select * from ddbba.rol
select * from ddbba.pago