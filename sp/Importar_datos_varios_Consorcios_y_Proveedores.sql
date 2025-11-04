--Se tienen que descargar access para poder exportar el archivo sql https://www.microsoft.com/en-us/download/details.aspx?id=54920&msockid=0563dc410f8e6bbc023dc9f70ef26a4b
use "consorcios"
go 

CREATE OR ALTER PROCEDURE ddbba.sp_importar_consorcios
    @NomArch VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- VARIABLES PARA SQL DINÁMICO
    DECLARE @BulkSQL NVARCHAR(MAX);
    DECLARE @DynamicSQL NVARCHAR(MAX);
    
    -- 0. Limpieza y Creación de la tabla temporal GLOBAL (##)
    DROP TABLE IF EXISTS ##temp_consorcios; 
    CREATE TABLE ##temp_consorcios
     (
        consorcio VARCHAR(12),
        nombre VARCHAR(50),
        domicilio VARCHAR(50),
        cant_UF SMALLINT,
        M2_totales INT
     );
    
    -- 1. Definición y Ejecución del BULK INSERT (para cargar el archivo)
    SET @BulkSQL = N'
    BULK INSERT ##temp_consorcios
    FROM ''' + @NomArch + N'''
    WITH
    (
        FIELDTERMINATOR = '';'',  -- Asumo que tu CSV usa punto y coma
        ROWTERMINATOR = ''0x0a'' -- Formato LF para archivos UNIX/Linux
    );';

    BEGIN TRY
        -- Ejecuta la carga del archivo
        EXEC sp_executesql @BulkSQL; 
        
    END TRY
    BEGIN CATCH
        PRINT 'Error durante el BULK INSERT. Verifique la ruta, permisos y formato.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS ##temp_consorcios;
        RETURN;
    END CATCH
    
    -- 2. ELIMINACIÓN DE DUPLICADOS (AHORA DINÁMICO)
    SET @DynamicSQL = N'
        DELETE t
        FROM ##temp_consorcios t  -- 
        WHERE EXISTS (
            SELECT 1
            FROM ddbba.consorcio c
            WHERE c.nombre = t.nombre
        );';
    EXEC sp_executesql @DynamicSQL; -- La compilación se difiere hasta este punto

    -- 3. INSERCIÓN FINAL (AHORA DINÁMICO)
    SET @DynamicSQL = N'
        INSERT INTO ddbba.consorcio (
            nombre,
            metros_cuadrados,
            direccion
        )
        SELECT
            t.nombre,
            t.M2_totales,  
            t.domicilio
        FROM ##temp_consorcios AS t;'; -- ¡CORREGIDO a ## y ejecutado dinámicamente!
    EXEC sp_executesql @DynamicSQL; -- La compilación se difiere hasta este punto
    
    -- 4. Limpia la tabla temporal global al terminar
    DROP TABLE IF EXISTS ##temp_consorcios;

END;
GO



-- 6. Ejecución
EXEC ddbba.sp_importar_consorcios
    @NomArch = 'C:\pruebas\datos_varios(Consorcios).csv';
GO
--Para ejecutar el SP
EXEC ddbba.sp_importar_consorcios
	@NomArch='C:\Users\Usuario\Desktop\TPBASEDDATOS\documentacion\Archivos para el TP\datos_varios(Consorcios).csv' --aca va la ruta de donde tengan el archivo


--Para ver si se inserto todo correctamente
select * from ddbba.consorcio
		
------------------------------------------------------------------------------------------------------------------------
----SP PARA Importar_datos_varios_proveedores
GO





CREATE OR ALTER PROCEDURE ddbba.sp_importar_proveedores
	@NomArch varchar(255) -- Debe contener la ruta COMPLETA del archivo CSV
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables para SQL Dinámico
    DECLARE @BulkSQL NVARCHAR(MAX);
    DECLARE @InsertSQL NVARCHAR(MAX); -- Nueva variable para el INSERT final
    
    -- 0. Limpieza y Creación de la tabla temporal GLOBAL (##)
    DROP TABLE IF EXISTS ##temp_proveedores; 
    
    CREATE TABLE ##temp_proveedores
     (	
        tipo_de_gasto VARCHAR(50),
        descripcion VARCHAR (100),
        detalle VARCHAR(100) NULL,
        nombre_consorcio VARCHAR (255)
     );

    -- 1. Definición y Ejecución del BULK INSERT
    SET @BulkSQL = N'
    BULK INSERT ##temp_proveedores
    FROM ''' + @NomArch + N'''
    WITH
    (
        FIELDTERMINATOR = '';'',     -- Asumo punto y coma
        ROWTERMINATOR = ''0x0a'',  
        FIRSTROW = 2                 -- Asumo que hay encabezados
    );';

    BEGIN TRY
        -- Ejecuta la carga del archivo
        EXEC sp_executesql @BulkSQL; 
        
    END TRY
    BEGIN CATCH
        PRINT 'Error durante el BULK INSERT. Verifique la ruta, permisos y formato.';
        PRINT ERROR_MESSAGE();
        DROP TABLE IF EXISTS ##temp_proveedores;
        RETURN;
    END CATCH
    
    -- 2. Inserto los datos de la tabla temporal a la tabla final (AHORA DINÁMICO)
    --    Esto resuelve el error de "no se pudo enlazar" las columnas.

    SET @InsertSQL = N'
        INSERT INTO ddbba.Proveedores(
            tipo_de_gasto,
            descripcion,
            detalle,
            nombre_consorcio
        )
        SELECT
            t.tipo_de_gasto,
            t.descripcion,
            t.detalle,
            t.nombre_consorcio
        FROM ##temp_proveedores AS t;
    ';

    -- Ejecuta la inserción final
    EXEC sp_executesql @InsertSQL; 

    -- 3. Limpia la tabla temporal global
    DROP TABLE IF EXISTS ##temp_proveedores;
    
END;
GO

--Para ejecutar el SP
EXEC ddbba.sp_importar_proveedores
	@NomArch='C:\pruebas\datos_varios(Proveedores).csv' --aca va la ruta de donde tengan el archivo(si o si tiene que ser en una carpeta disco c para los permisos)

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
EXEC xp_fileexist 'C:\Users\Usuario\Desktop\TPBASEDDATOS\documentacion\Archivos para el TP\datos varios.xlsx';
