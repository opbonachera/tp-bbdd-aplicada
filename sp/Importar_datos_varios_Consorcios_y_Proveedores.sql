--Se tienen que descargar access para poder exportar el archivo sql https://www.microsoft.com/en-us/download/details.aspx?id=54920&msockid=0563dc410f8e6bbc023dc9f70ef26a4b
use "consorcios"
go 

CREATE OR ALTER PROCEDURE ddbba.sp_importar_consorcios
	@NomArch varchar(255)
AS
BEGIN
 
--creacion de la tabla temporal
 CREATE TABLE #temp_consorcios
 ( consorcio varchar(12),
   nombre varchar(50),
   domicilio varchar (50),
   cant_UF smallint,
   M2_totales int
  );
--inserto los datos del archivo excel a la tabla temporal con openrowset(lee datos desde un archivo)
--Uso sql dinamico
   DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        INSERT INTO #temp_consorcios (consorcio, nombre, domicilio, cant_UF, M2_totales)
        SELECT Consorcio, [Nombre del consorcio], Domicilio, [Cant unidades funcionales], [m2 totales]
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;Database=' + @NomArch + ';HDR=YES'',
            ''SELECT * FROM [Consorcios$]''
        );
    ';

--ejecuto el sql dinamico
    EXEC sp_executesql @sql;

--Inserto los datos en la tabla original
	INSERT INTO ddbba.consorcio(
	consorcio ,
    nombre,
    metros_cuadrados ,
    direccion,
	cant_UF,
    cbu)
	select
	t.consorcio,
	t.nombre,
	t.M2_totales,
	t.domicilio,
	t.cant_UF,
	RIGHT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 22) AS cbu --genera los cbus
	from #temp_consorcios as t

	--elimino la tabla temporal
	DROP TABLE #temp_consorcios
END
GO
--Para ejecutar el SP
EXEC ddbba.sp_importar_consorcios
	@NomArch='C:\Importar_TP\datos varios.xlsx' --aca va la ruta de donde tengan el archivo


--Para ver si se inserto todo correctamente
select * from ddbba.consorcio
		
------------------------------------------------------------------------------------------------------------------------
----SP PARA Importar_datos_varios_proveedores

CREATE OR ALTER PROCEDURE ddbba.sp_importar_proveedores
	@NomArch varchar(255)
AS
BEGIN
 
--creacion de la tabla temporal
 CREATE TABLE #temp_proveedores
 (  tipo_de_gasto VARCHAR(50),
	descripcion VARCHAR (100),
	detalle VARCHAR(100) NULL,
	nombre_consorcio VARCHAR (255),
  );
--inserto los datos del archivo excel a la tabla temporal con openrowset(lee datos desde un archivo)
--Uso sql dinamico
   DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        INSERT INTO #temp_proveedores (tipo_de_gasto,descripcion,detalle,nombre_consorcio)
        SELECT F1 as tipo_de_gasto, F2 as descripcion,F3 as detalle, F4 as nombre_consorcio
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;Database=' + @NomArch + ';HDR=NO'',
            ''SELECT * FROM [Proveedores$]''
        );
    ';

--ejecuto el sql dinamico
    EXEC sp_executesql @sql;

--Inserto los datos en la tabla original
	INSERT INTO ddbba.Proveedores(
	tipo_de_gasto,
	descripcion,
	detalle,
	nombre_consorcio
	)
	select
	t.tipo_de_gasto,
	t.descripcion,
	t.detalle,
	t.nombre_consorcio

	from #temp_proveedores as t

	--elimino la tabla temporal
	DROP TABLE #temp_proveedores
END
GO

--Para ejecutar el SP
EXEC ddbba.sp_importar_proveedores
	@NomArch='C:\Importar_TP\datos varios.xlsx' --aca va la ruta de donde tengan el archivo

--Para ver si se inserto todo correctamente
select * from ddbba.proveedores
-------------------------------------------------------------------------------------------------------------------------------
--ESTO ES POR SI ALGO NO LES ANDA
--Habilita opciones avanzadas
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

--Habilita consultas ad hoc
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.12.0', 'AllowInProcess', 1;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.12.0', 'DynamicParameters', 1;

--para saber si sql encuentra el archivo
EXEC xp_fileexist 'C:\Importar_TP\datos varios.xlsx';
