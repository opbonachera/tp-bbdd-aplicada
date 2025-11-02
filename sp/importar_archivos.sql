-- aca modifiquen el 
create or alter procedure ddbba.sp_importar_archivos
as
begin
	
	exec ddbba.sp_importar_consorcios @ruta_archivo = '\app\datasets\tp\datosvarios_consorcios.csv'
	exec ddbba.sp_importar_pagos @ruta_archivo = '\app\datasets\tp\pagos_consorcios.csv'
	exec ddbba.sp_importar_uf_por_consorcios @ruta_archivo = '\app\datasets\tp\UF por consorcio.txt'
	exec ddbba.sp_importar_inquilinos_propietarios @ruta_archivo = '\app\datasets\tp\Inquilino-propietarios-datos.csv'
	exec ddbba.sp_relacionar_pagos
	exec ddbba.sp_importar_servicios @ruta_archivo = '\app\datasets\tp\Servicios.Servicios.json', @anio=2025
end

exec ddbba.sp_importar_archivos
