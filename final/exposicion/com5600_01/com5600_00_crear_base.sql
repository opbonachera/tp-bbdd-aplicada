/*---------------------------------------------------------
 Materia:     Base de datos aplicada. 
 Grupo:       1
 Comision:    5600
 Fecha:       2025-01-01
 Descripcion: Creacion de base de datos, esquema y tablas.
 Integrantes: Arcón Wogelman, Nazareno — 44792096
              Arriola Santiago — 41743980 
              Bonachera Ornella — 46119546
              Benitez Jimena — 46097948
              Guardia Gabriel — 42364065
              Perez, Olivia Constanza — 46641730
----------------------------------------------------------*/
IF DB_ID('Com5600_Grupo01') IS NOT NULL
BEGIN
    USE Com5600_Grupo01;
END
GO

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  ELIMINACION DE BASE DE DATOS Y OBJETOS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*--- Eliminación de índices ---*/
DROP INDEX IF EXISTS IX_pago_fecha_unidad_monto ON finanzas.pago;
DROP INDEX IF EXISTS IX_unidad_funcional_departamento ON consorcios.unidad_funcional;
DROP INDEX IF EXISTS IX_expensa_consorcio_fecha ON finanzas.expensa;
DROP INDEX IF EXISTS IX_gastos_ordinarios_expensa ON finanzas.gastos_ordinarios;
DROP INDEX IF EXISTS IX_gasto_extraordinario_expensa ON finanzas.gasto_extraordinario;
DROP INDEX IF EXISTS IX_pago_consorcio_fecha_estado ON finanzas.pago;
DROP INDEX IF EXISTS IX_detalle_expensas_por_uf_unidad_consorcio_expensa ON finanzas.detalle_expensas_por_uf;
DROP INDEX IF EXISTS IX_expensa_fecha_emision ON finanzas.expensa;
DROP INDEX IF EXISTS IX_rol_propietario ON personas.rol;
DROP INDEX IF EXISTS IX_unidad_funcional_consorcio ON consorcios.unidad_funcional;
DROP INDEX IF EXISTS IX_persona_documento ON personas.persona;
DROP INDEX IF EXISTS IX_pago_consorcio_uf_fecha ON finanzas.pago;
GO

/*--- Eliminación de funciones ---*/
DROP FUNCTION IF EXISTS utils.fn_normalizar_monto;
DROP FUNCTION IF EXISTS utils.fn_limpiar_espacios;
GO

/*--- Eliminación de stored procedures ---*/
DROP PROCEDURE IF EXISTS utils.sp_generar_tipos_envio;
DROP PROCEDURE IF EXISTS utils.sp_generar_envios_expensas;
DROP PROCEDURE IF EXISTS utils.sp_generar_estado_financiero;
DROP PROCEDURE IF EXISTS utils.sp_generar_gastos_extraordinarios;
DROP PROCEDURE IF EXISTS utils.sp_generar_cuotas;
DROP PROCEDURE IF EXISTS utils.sp_generar_pagos;
DROP PROCEDURE IF EXISTS utils.sp_generar_vencimientos_expensas;
DROP PROCEDURE IF EXISTS utils.sp_generar_detalle_expensas_por_uf;
DROP PROCEDURE IF EXISTS consorcios.sp_importar_consorcios;
DROP PROCEDURE IF EXISTS personas.sp_importar_proveedores;
DROP PROCEDURE IF EXISTS finanzas.sp_importar_pagos;
DROP PROCEDURE IF EXISTS consorcios.sp_importar_uf_por_consorcios;
DROP PROCEDURE IF EXISTS personas.sp_importar_inquilinos_propietarios;
DROP PROCEDURE IF EXISTS finanzas.sp_importar_servicios;
DROP PROCEDURE IF EXISTS personas.sp_relacionar_inquilinos_uf;
DROP PROCEDURE IF EXISTS finanzas.sp_relacionar_pagos;
DROP PROCEDURE IF EXISTS utils.sp_actualizar_prorrateo;
GO

/*--- Eliminación de tablas ---*/
DROP TABLE IF EXISTS finanzas.detalle_expensas_por_uf;
DROP TABLE IF EXISTS finanzas.estado_financiero;
DROP TABLE IF EXISTS finanzas.pago;
DROP TABLE IF EXISTS gestion.envio_expensa;
DROP TABLE IF EXISTS finanzas.cuotas;
DROP TABLE IF EXISTS finanzas.gasto_extraordinario;
DROP TABLE IF EXISTS finanzas.gastos_ordinarios;
DROP TABLE IF EXISTS finanzas.expensa;
DROP TABLE IF EXISTS personas.rol;
DROP TABLE IF EXISTS consorcios.unidad_funcional;
DROP TABLE IF EXISTS gestion.tipo_envio;
DROP TABLE IF EXISTS finanzas.tipo_gasto;
DROP TABLE IF EXISTS personas.persona;
DROP TABLE IF EXISTS personas.proveedores;
DROP TABLE IF EXISTS consorcios.consorcio;
GO

/*--- Eliminación de base de datos ---*/
USE master;
ALTER DATABASE Com5600_Grupo01
SET SINGLE_USER WITH ROLLBACK IMMEDIATE; -- Para forzar eliminación aunque haya conexiones

DROP DATABASE Com5600_Grupo01;

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DE ELIMINACION DE BASE DE DATOS Y OBJETOS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CREACION DE LA BASE DE DATOS Y TABLAS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*--- Creación de la db ---*/
CREATE DATABASE Com5600_Grupo01;
GO

USE Com5600_Grupo01;
GO

/*--- Creación de esquemas lógicos ---*/
CREATE SCHEMA consorcios; -- Objetos relacionados a los consorcios y las uf
GO
CREATE SCHEMA personas; --Objetos que manejan datos de personas
GO
CREATE SCHEMA finanzas; -- Objetos relacionados a la gestion financiera del consorcio
GO
CREATE SCHEMA gestion; -- Objetos relacionados a la gestion del consorcio ej. envío de expensas
GO
CREATE SCHEMA utils; -- Objetos que añaden funcionalidades extra, por ejemplo generar datos adicionales
GO
CREATE SCHEMA datos; -- Reportes
GO
CREATE SCHEMA seguridad; -- Objetos relacionados a la seguridad, roles y permisos
GO
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  FIN DE CREACION DE BASE DE DATOS <<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  CREACION DE TABLAS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
CREATE TABLE consorcios.consorcio (
    id_consorcio INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50),
    metros_cuadrados INT,
    direccion VARCHAR(100),
    cant_UF SMALLINT
);
GO

-- Tabla proveedores
CREATE TABLE personas.proveedores (
    id_proveedores INT PRIMARY KEY IDENTITY(1,1),
    tipo_de_gasto VARCHAR(50),
    entidad VARCHAR(100),
    detalle VARCHAR(120) NULL,
    nombre_consorcio VARCHAR(80)
);
GO

-- Tabla persona
CREATE TABLE personas.persona (
    nro_documento BIGINT,
    tipo_documento VARCHAR(10),
    nombre VARCHAR(50),
    mail VARCHAR(100),
    telefono VARCHAR(20),
    cbu VARCHAR(30),
    PRIMARY KEY (nro_documento, tipo_documento)
);
GO

-- Tabla tipo_gasto
CREATE TABLE finanzas.tipo_gasto (
    id_tipo_gasto INT PRIMARY KEY IDENTITY(1,1),
    detalle VARCHAR(100)
);
GO

-- Tabla tipo_envio
CREATE TABLE gestion.tipo_envio (
    id_tipo_envio INT PRIMARY KEY IDENTITY(1,1),
    detalle VARCHAR(100)
);
GO

-- Tabla unidad_funcional (PK compuesta)
CREATE TABLE consorcios.unidad_funcional (
    id_unidad_funcional INT NOT NULL,
    id_consorcio INT NOT NULL,
    metros_cuadrados INT,
    piso CHAR(2),
    departamento CHAR(10),
    cochera BIT DEFAULT 0,
    baulera BIT DEFAULT 0,
    coeficiente FLOAT,
    saldo_anterior decimal(12,3) DEFAULT 0.00,
    cbu VARCHAR(30),
    prorrateo FLOAT DEFAULT 0,
    CONSTRAINT PK_unidad_funcional PRIMARY KEY (id_unidad_funcional, id_consorcio),
    FOREIGN KEY (id_consorcio) REFERENCES consorcios.consorcio(id_consorcio) ON DELETE CASCADE
);
GO

-- Tabla rol
CREATE TABLE personas.rol (
    id_rol INT PRIMARY KEY IDENTITY(1,1),
    id_unidad_funcional INT NOT NULL,
    id_consorcio INT NOT NULL,
    nro_documento BIGINT,
    tipo_documento VARCHAR(10),
    nombre_rol VARCHAR(50),
    activo BIT DEFAULT 1,
    fecha_inicio DATE,
    fecha_fin DATE,
    FOREIGN KEY (id_unidad_funcional, id_consorcio) 
        REFERENCES consorcios.unidad_funcional(id_unidad_funcional, id_consorcio) ON DELETE CASCADE,
    FOREIGN KEY (nro_documento, tipo_documento) 
        REFERENCES personas.persona(nro_documento, tipo_documento) ON DELETE CASCADE
);
GO

-- Tabla expensa
CREATE TABLE finanzas.expensa (
    id_expensa INT PRIMARY KEY IDENTITY(1,1),
    id_consorcio INT NOT NULL,
    fecha_emision DATE,
    primer_vencimiento DATE,
    segundo_vencimiento DATE,
    FOREIGN KEY (id_consorcio) REFERENCES consorcios.consorcio(id_consorcio) ON DELETE CASCADE
);
GO

-- Tabla gastos_ordinarios
CREATE TABLE finanzas.gastos_ordinarios (
    id_gasto_ordinario INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT,
    id_tipo_gasto INT,
    detalle VARCHAR(200),
    nro_factura VARCHAR(50),
    importe decimal(12,3),
    FOREIGN KEY (id_expensa) REFERENCES finanzas.expensa(id_expensa) ON DELETE CASCADE,
    FOREIGN KEY (id_tipo_gasto) REFERENCES finanzas.tipo_gasto(id_tipo_gasto)
);
GO

-- Tabla gasto_extraordinario
CREATE TABLE finanzas.gasto_extraordinario (
    id_gasto_extraordinario INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT,
    detalle VARCHAR(200),
    total_cuotas INT DEFAULT 1,
    pago_en_cuotas BIT DEFAULT 0,
    importe_total decimal(12,3),
    FOREIGN KEY (id_expensa) REFERENCES finanzas.expensa(id_expensa) ON DELETE CASCADE
);
GO

-- Tabla cuotas
CREATE TABLE finanzas.cuotas (
    id_gasto_extraordinario INT,
    nro_cuota INT,
    PRIMARY KEY (id_gasto_extraordinario, nro_cuota),
    FOREIGN KEY (id_gasto_extraordinario) REFERENCES finanzas.gasto_extraordinario(id_gasto_extraordinario) ON DELETE CASCADE
);
GO

-- Tabla envio_expensa
CREATE TABLE gestion.envio_expensa (
    id_envio INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT NOT NULL,
    id_unidad_funcional INT NOT NULL,
    id_consorcio INT NOT NULL,
    id_tipo_envio INT NOT NULL,
    destinatario_nro_documento BIGINT,
    destinatario_tipo_documento VARCHAR(10),
    fecha_envio DATETIME,
    FOREIGN KEY (id_expensa) REFERENCES finanzas.expensa(id_expensa) ON DELETE CASCADE,
    FOREIGN KEY (id_unidad_funcional, id_consorcio) REFERENCES consorcios.unidad_funcional(id_unidad_funcional, id_consorcio),
    FOREIGN KEY (id_tipo_envio) REFERENCES gestion.tipo_envio(id_tipo_envio),
    FOREIGN KEY (destinatario_nro_documento, destinatario_tipo_documento) 
        REFERENCES personas.persona(nro_documento, tipo_documento) ON DELETE CASCADE
);
GO

-- Tabla pago

CREATE TABLE finanzas.pago (
    id_pago INT PRIMARY KEY,
    id_unidad_funcional INT,
    id_consorcio INT,
    id_expensa INT,
    fecha_pago DATETIME,
    monto decimal(12,3),
    cbu_origen VARCHAR(30),
    estado VARCHAR(30),
    FOREIGN KEY (id_unidad_funcional, id_consorcio) REFERENCES consorcios.unidad_funcional(id_unidad_funcional, id_consorcio) ON DELETE CASCADE,
    FOREIGN KEY (id_expensa) REFERENCES finanzas.expensa(id_expensa)
);
GO

-- Tabla estado_financiero
CREATE TABLE finanzas.estado_financiero (
    id_expensa INT PRIMARY KEY,
    saldo_anterior decimal(12,3),
    ingresos_en_termino decimal(12,3),
    ingresos_adelantados decimal(12,3),
    ingresos_adeudados decimal(12,3),
    egresos_del_mes decimal(12,3),
    saldo_cierre decimal(12,3),
    FOREIGN KEY (id_expensa) REFERENCES finanzas.expensa(id_expensa) ON DELETE CASCADE
);
GO

-- Tabla detalle_expensas_por_uf
CREATE TABLE finanzas.detalle_expensas_por_uf (
    id_detalle INT NOT NULL,
    id_expensa INT NOT NULL,
    id_unidad_funcional INT NOT NULL,
    id_consorcio INT NOT NULL,
    gastos_ordinarios INT,
    gastos_extraordinarios INT,
    deuda INT,
    interes_mora INT,
    monto_total INT,
    PRIMARY KEY (id_detalle, id_expensa, id_unidad_funcional, id_consorcio),
    FOREIGN KEY (id_expensa) REFERENCES finanzas.expensa(id_expensa) ON DELETE CASCADE,
    FOREIGN KEY (id_unidad_funcional, id_consorcio) REFERENCES consorcios.unidad_funcional(id_unidad_funcional, id_consorcio)
);
GO

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  FIN DE CREACION DE TABLAS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  CREACION DE FUNCIONES <<<<<<<<<<<<<<<<<<<<<<<<<<*/
CREATE OR ALTER FUNCTION utils.fn_normalizar_monto (@valor VARCHAR(50))
RETURNS DECIMAL(12,2)
AS
BEGIN

/* En esta funcion recibimos un valor monetario y lo convertimos en decimal(12,2), siguiendo estas reglas:
1) Limpiamos simbolos y espacios (caracteres no deseados)
2) Detectamos si tiene separador decimal
3) Eliminamos todos los separadores
4) Si tenia separador, insertamos el punto decimal
5) Devolvemos el numero normalizado
*/

    DECLARE @resultado NVARCHAR(50);
    DECLARE @tieneSeparador BIT;

    -- 1) Limpiamos caracteres no deseados
    SET @resultado = utils.fn_limpiar_espacios(LTRIM(RTRIM(ISNULL(@valor, '')))); --Borra espacios izq, der y entre medio
    SET @resultado = REPLACE(@resultado, '$', ''); --Saca el $ (si lo tuviese)

    -- 2) Detectamos si tiene separador decimal
    SET @tieneSeparador = CASE 
                            WHEN CHARINDEX(',', @resultado) > 0 OR CHARINDEX('.', @resultado) > 0 --CHARINDEX nos busca la primer aparicion del caracter, si es > 0 -> quiere decir que hay por lo menos UNO de los separadores (ya sea coma o punto)
                            THEN 1 
                            ELSE 0 
                          END;

    -- 3) Eliminamos todos los separadores
    SET @resultado = REPLACE(@resultado, ',', '');
    SET @resultado = REPLACE(@resultado, '.', '');

    -- 4) Si tenia separador, insertamos el punto decimal
    IF @tieneSeparador = 1 AND LEN(@resultado) > 2 --En el caso de que tenga tres digitos o mas,
        SET @resultado = STUFF(@resultado, LEN(@resultado) - 1, 0, '.'); --apuntamos a la posicion justo antes de los ultimos dos digitos (asumimos dos digitos decimales)
    --Si el numero tiene uno o dos digitos, entonces no entra al if y cuando castee solo le agrega el .00

    -- 5) Devolvemos el número normalizado
    RETURN ISNULL(TRY_CAST(@resultado AS DECIMAL(12,2)), 0.00); --Trata de castear el texto a decimal, si no puede, devuelve null y lo transformamos a 0.00
END
GO

CREATE OR ALTER FUNCTION utils.fn_limpiar_espacios (@valor VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
--- Limpia los espacios de una cadena de caracteres
    DECLARE @resultado VARCHAR(MAX) = @valor;

    SET @resultado = REPLACE(@resultado, CHAR(32), ''); 
    SET @resultado = REPLACE(@resultado, CHAR(160), '');
    SET @resultado = REPLACE(@resultado, CHAR(9), '');
    SET @resultado = REPLACE(@resultado, CHAR(10), '');
    SET @resultado = REPLACE(@resultado, CHAR(13), '');

    RETURN @resultado;
END
GO
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  FIN DE CREACION DE FUNCIONES <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  FIN DEL SCRIPT <<<<<<<<<<<<<<<<<<<<<<<<<<*/