-- aca modifiquen el path
create or alter procedure ddbba.sp_importar_archivos
as
begin	
	exec ddbba.sp_importar_consorcios_csv @ruta_archivo = '/app/datasets/tp/datosvarios_consorcios.csv'
	exec ddbba.sp_importar_pagos @ruta_archivo = '/app/datasets/tp/pagos_consorcios.csv'
	exec ddbba.sp_importar_uf_por_consorcios @ruta_archivo =  '/app/datasets/tp/UF por consorcio.txt'
	exec ddbba.sp_importar_inquilinos_propietarios @ruta_archivo = '/app/datasets/tp/Inquilino-propietarios-datos-final.csv'
	exec ddbba.sp_importar_servicios @ruta_archivo = '/var/opt/mssql/tp/Servicios.Servicios.json', @anio=2025
	exec ddbba.sp_relacionar_inquilinos_uf  @ruta_archivo = '/app/datasets/tp/Inquilino-propietarios-UF.csv'
end

exec ddbba.sp_importar_archivos