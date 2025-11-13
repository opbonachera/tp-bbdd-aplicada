-- =========================================================== --
-- Crea logins, usuarios, roles, permisos y vistas de auditoría --
-- =========================================================== --

CREATE LOGIN usuario1 WITH PASSWORD = 'Password123!';
CREATE LOGIN usuario2 WITH PASSWORD = 'Password123!';
CREATE LOGIN usuario3 WITH PASSWORD = 'Password123!';
CREATE LOGIN usuario4 WITH PASSWORD = 'Password123!';
GO

---------------------------------------------------------------
-- CREACIÓN DE USUARIOS EN LA BASE DE DATOS
---------------------------------------------------------------
USE [consorcios];
GO

CREATE USER usuario1 FOR LOGIN usuario1;
CREATE USER usuario2 FOR LOGIN usuario2;
CREATE USER usuario3 FOR LOGIN usuario3;
CREATE USER usuario4 FOR LOGIN usuario4;
GO

GRANT CONNECT TO usuario1, usuario2, usuario3, usuario4;
GO


---------------------------------------------------------------
-- CREACIÓN DE ROLES
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
-- ASIGNACIÓN DE USUARIOS A ROLES
---------------------------------------------------------------
ALTER ROLE rol_administrativo_general ADD MEMBER usuario1;
ALTER ROLE rol_administrativo_operativo ADD MEMBER usuario2;
ALTER ROLE rol_administrativo_bancario ADD MEMBER usuario3;
ALTER ROLE rol_sistemas ADD MEMBER usuario4;

-- Un usuario en más de un rol
ALTER ROLE rol_administrativo_general ADD MEMBER usuario3;
GO


---------------------------------------------------------------
-- ASIGNACIÓN DE PERMISOS A ROLES
---------------------------------------------------------------

-- Permisos sobre tabla unidad_funcional
GRANT INSERT, DELETE, UPDATE, SELECT 
ON ddbba.unidad_funcional 
TO rol_administrativo_general, rol_administrativo_operativo;
GO

-- Procedimientos de mantenimiento
GRANT EXECUTE ON OBJECT::ddbba.sp_relacionar_inquilinos_uf 
TO rol_administrativo_general, rol_administrativo_operativo;

GRANT EXECUTE ON OBJECT::ddbba.sp_importar_uf_por_consorcios 
TO rol_administrativo_general, rol_administrativo_operativo;
GO

-- Reportes disponibles para todos los roles
GRANT EXECUTE ON OBJECT::ddbba.sp_reporte_1 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::ddbba.sp_reporte_2 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::ddbba.sp_reporte_3 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::ddbba.sp_reporte_4 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::ddbba.sp_reporte_5 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::ddbba.sp_reporte_6 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;
GO

---------------------------------------------------------------
--ASIGNACIÓN DE PERMISOS FALTANTES PARA SQL DINÁMICO
---------------------------------------------------------------
-- Los reportes (sp_reporte_1, sp_reporte_2) usan SQL dinámico.
-- Esto rompe la cadena de propiedad, por lo que los roles
-- necesitan permiso SELECT directo sobre las tablas consultadas.

-- Permiso sobre ddbba.pago (usada en sp_reporte_1 y sp_reporte_2)
GRANT SELECT ON ddbba.pago
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;
GO

-- Permiso sobre ddbba.expensa (usada en sp_reporte_1)
GRANT SELECT ON ddbba.expensa
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;
GO

-- Permiso sobre ddbba.gastos_ordinarios (usada en sp_reporte_1)
GRANT SELECT ON ddbba.gastos_ordinarios
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;
GO

-- Permiso sobre ddbba.gasto_extraordinario (usada en sp_reporte_1)
GRANT SELECT ON ddbba.gasto_extraordinario
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;
GO

-- Permiso sobre ddbba.unidad_funcional (usada en sp_reporte_2)
GRANT SELECT ON ddbba.unidad_funcional
TO rol_administrativo_bancario, rol_sistemas;
GO
