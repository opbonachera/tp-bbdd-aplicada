--Se tienen que descargar access para poder exportar el archivo sql https://www.microsoft.com/en-us/download/details.aspx?id=54920&msockid=0563dc410f8e6bbc023dc9f70ef26a4b
USE consorcios;
GO

CREATE OR ALTER PROCEDURE ddbba.sp_importar_consorcios
	@NomArch varchar(255)
AS
BEGIN
 
--creacion de la tabla temporal
 CREATE TABLE #temp_consorcios
 ( consorcio varchar(12),
   nombre varchar(80),
   domicilio varchar (40),
   cant_UF smallint,
   M2_totales int
  );
--inserto los datos del archivo excel a la tabla temporal con openrowset(lee datos desde un archivo)
--Uso sql dinamico (OPENROWSET por extensión .xlsx)
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
    nombre,
    metros_cuadrados ,
    direccion,
	cant_UF
	)
	select
	t.nombre,
	t.M2_totales,
	t.domicilio,
	t.cant_UF

	from #temp_consorcios as t

	--elimino la tabla temporal
	DROP TABLE #temp_consorcios
END
GO



--Habilita opciones avanzadas
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

--Habilita consultas ad hoc
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.12.0', 'AllowInProcess', 1;
EXEC sp_MSset_oledb_prop 'Microsoft.ACE.OLEDB.12.0', 'DynamicParameters', 1;

--para saber si sql encuentra el archivo
EXEC xp_fileexist 'C:\Importar_TP\Inquilino-propietarios-datos.csv';
