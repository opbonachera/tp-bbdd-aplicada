use "consorcios"
go

----SP PARA Importar_datos_varios_proveedores
CREATE OR ALTER PROCEDURE ddbba.sp_importar_proveedores
	@NomArch varchar(255)
AS
BEGIN
 
--creacion de la tabla temporal
 CREATE TABLE #temp_proveedores
 (  tipo_de_gasto VARCHAR(50),
	entidad VARCHAR (100),
	detalle VARCHAR(120) NULL,
	nombre_consorcio VARCHAR (80),
  );
--inserto los datos del archivo excel a la tabla temporal con openrowset(lee datos desde un archivo)
--Uso sql dinamico
   DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
        INSERT INTO #temp_proveedores (tipo_de_gasto, entidad, detalle, nombre_consorcio)
        SELECT 
              F1,  -- columna sin encabezado
              F2,  -- columna sin encabezado
              F3,  -- columna sin encabezado
              [Nombre del consorcio]  -- única con encabezado
        FROM OPENROWSET(
             ''Microsoft.ACE.OLEDB.12.0'',
             ''Excel 12.0;HDR=YES;Database=' + @NomArch + ''',
             ''SELECT * FROM [Proveedores$]''
        );';

--ejecuto el sql dinamico
    EXEC sp_executesql @sql;

--Inserto los datos en la tabla original (sin duplicados)
INSERT INTO ddbba.Proveedores (
    tipo_de_gasto,
    entidad,
    detalle,
    nombre_consorcio
)
SELECT
    t.tipo_de_gasto,
    CASE 
        WHEN LOWER(t.entidad) LIKE '%serv. limpieza%' THEN t.detalle
        ELSE t.entidad
    END AS entidad,
    CASE 
        WHEN LOWER(t.entidad) LIKE '%serv. limpieza%' THEN t.entidad
        ELSE t.detalle
    END AS detalle,
    t.nombre_consorcio
FROM #temp_proveedores AS t
WHERE NOT EXISTS (
    SELECT 1
    FROM ddbba.Proveedores p
    WHERE 
        p.tipo_de_gasto = t.tipo_de_gasto
        AND p.entidad = 
            CASE 
                WHEN LOWER(t.entidad) LIKE '%serv. limpieza%' THEN t.detalle
                ELSE t.entidad
            END
        AND ISNULL(p.detalle, '') = ISNULL(
            CASE 
                WHEN LOWER(t.entidad) LIKE '%serv. limpieza%' THEN t.entidad
                ELSE t.detalle
            END, ''
        )
        AND p.nombre_consorcio = t.nombre_consorcio
);

	--elimino la tabla temporal
	DROP TABLE #temp_proveedores
END
GO