-- aca modifiquen el path
create or alter procedure ddbba.sp_importar_archivos
as
begin	
	exec ddbba.sp_importar_consorcios_csv @ruta_archivo =
	exec ddbba.sp_importar_pagos @ruta_archivo =
	exec ddbba.sp_importar_uf_por_consorcios @ruta_archivo = 
	exec ddbba.sp_importar_inquilinos_propietarios @ruta_archivo =
	--exec ddbba.sp_importar_servicios @ruta_archivo = '/var/opt/mssql/tp/Servicios.Servicios.json', @anio=2025
	exec ddbba.sp_relacionar_inquilinos_uf  @ruta_archivo =
end

exec ddbba.sp_importar_archivos


delete from ddbba.rol
select * from ddbba.rol r 
inner join ddbba.unidad_funcional uf on r.id_unidad_funcional = uf.id_unidad_funcional

select * from ddbba.unidad_funcional
select count(*), r.id_consorcio from ddbba.rol r
group by r.id_consorcio

select * from ddbba.unidad_funcional

select * from  ddbba.consorcio

