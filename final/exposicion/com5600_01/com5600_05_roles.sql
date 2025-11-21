/*---------------------------------------------------------
 Materia:     Base de datos aplicada. 
 Grupo:       1
 Comision:    5600
 Fecha:       2025-01-01
 Descripcion: Creacion de logins, usuarios y roles. 
 Integrantes: Arc�n Wogelman, Nazareno � 44792096
              Arriola Santiago � 41743980 
              Bonachera Ornella � 46119546
              Benitez Jimena � 46097948
              Guardia Gabriel � 42364065
              Perez, Olivia Constanza � 46641730
----------------------------------------------------------*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  INICIO DEL SCRIPT <<<<<<<<<<<<<<<<<<<<<<<<<<*/
IF DB_ID('Com5600_Grupo01') IS NOT NULL
BEGIN
    USE Com5600_Grupo01;
END
GO

-- =========================================================== --
-- Crea logins, usuarios, roles, permisos y vistas de auditor?a --
-- =========================================================== --

CREATE LOGIN usuario1 WITH PASSWORD = 'Password123!';
CREATE LOGIN usuario2 WITH PASSWORD = 'Password123!';
CREATE LOGIN usuario3 WITH PASSWORD = 'Password123!';
CREATE LOGIN usuario4 WITH PASSWORD = 'Password123!';
GO

---------------------------------------------------------------
-- CREACI?N DE USUARIOS EN LA BASE DE DATOS
---------------------------------------------------------------


CREATE USER usuario1 FOR LOGIN usuario1;
CREATE USER usuario2 FOR LOGIN usuario2;
CREATE USER usuario3 FOR LOGIN usuario3;
CREATE USER usuario4 FOR LOGIN usuario4;
GO

GRANT CONNECT TO usuario1, usuario2, usuario3, usuario4;
GO

---------------------------------------------------------------
-- CREACI?N DE ROLES
---------------------------------------------------------------
CREATE ROLE rol_administrativo_general;
GO
CREATE ROLE rol_administrativo_bancario;
GO
CREATE ROLE rol_administrativo_operativo;
GO
CREATE ROLE rol_sistemas;
GO


---------------------------------------------------------------
-- ASIGNACI?N DE USUARIOS A ROLES
---------------------------------------------------------------
ALTER ROLE rol_administrativo_general ADD MEMBER usuario1;
ALTER ROLE rol_administrativo_operativo ADD MEMBER usuario2;
ALTER ROLE rol_administrativo_bancario ADD MEMBER usuario3;
ALTER ROLE rol_sistemas ADD MEMBER usuario4;

-- Un usuario en m?s de un rol
ALTER ROLE rol_administrativo_general ADD MEMBER usuario3;
GO


---------------------------------------------------------------
-- ASIGNACI?N DE PERMISOS A ROLES
---------------------------------------------------------------

-- Permisos sobre tabla unidad_funcional
GRANT INSERT, DELETE, UPDATE, SELECT 
ON consorcios.unidad_funcional 
TO rol_administrativo_general, rol_administrativo_operativo;
GO

-- Procedimientos de mantenimiento
GRANT EXECUTE ON OBJECT::consorcios.sp_relacionar_inquilinos_uf 
TO rol_administrativo_general, rol_administrativo_operativo;

GRANT EXECUTE ON OBJECT::consorcios.sp_importar_uf_por_consorcios 
TO rol_administrativo_general, rol_administrativo_operativo;
GO

-- Reportes disponibles para todos los roles
GRANT EXECUTE ON OBJECT::datos.sp_reporte_1 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::datos.sp_reporte_2 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::datos.sp_reporte_3 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::datos.sp_reporte_4 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::datos.sp_reporte_5 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::datos.sp_reporte_6 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;
GO