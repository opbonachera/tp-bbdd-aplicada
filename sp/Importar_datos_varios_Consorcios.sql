
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
