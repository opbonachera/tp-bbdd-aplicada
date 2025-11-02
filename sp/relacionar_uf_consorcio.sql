create or alter procedure ddbba.sp_relacionar_uf_consorcio 
as
begin
	select * from ddbba.consorcio;
	select * from ddbba.unidad_funcional;

	insert into ddbba.unidad_funcional uf(id_consorcio)
	select id_consorcio 
	from ddbba.consorcio c
	where c.nombre = uf.nombre
end

select * from ddbba.unidad_funcional
exec ddbba.sp_relacionar_uf_consorcio
