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
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  INICIO DEL SCRIPT <<<<<<<<<<<<<<<<<<<<<<<<<<*/
USE Com5600_Grupo01;
GO
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  ELIMINACION DE BASE DE DATOS Y OBJETOS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*--- Eliminación de índices ---*/
DROP INDEX IF EXISTS IX_pago_fecha_unidad_monto ON ddbba.pago;
DROP INDEX IF EXISTS IX_unidad_funcional_departamento ON ddbba.unidad_funcional;
DROP INDEX IF EXISTS IX_expensa_consorcio_fecha ON ddbba.expensa;
DROP INDEX IF EXISTS IX_gastos_ordinarios_expensa ON ddbba.gastos_ordinarios;
DROP INDEX IF EXISTS IX_gasto_extraordinario_expensa ON ddbba.gasto_extraordinario;
DROP INDEX IF EXISTS IX_pago_consorcio_fecha_estado ON ddbba.pago;
DROP INDEX IF EXISTS IX_detalle_expensas_por_uf_unidad_consorcio_expensa ON ddbba.detalle_expensas_por_uf;
DROP INDEX IF EXISTS IX_expensa_fecha_emision ON ddbba.expensa;
DROP INDEX IF EXISTS IX_rol_propietario ON ddbba.rol;
DROP INDEX IF EXISTS IX_unidad_funcional_consorcio ON ddbba.unidad_funcional;
DROP INDEX IF EXISTS IX_persona_documento ON ddbba.persona;
DROP INDEX IF EXISTS IX_pago_consorcio_uf_fecha ON ddbba.pago;
GO

/*--- Eliminación de funciones ---*/
DROP FUNCTION IF EXISTS ddbba.fn_normalizar_monto;
DROP FUNCTION IF EXISTS ddbba.fn_limpiar_espacios;
GO

/*--- Eliminación de stored procedures ---*/
DROP PROCEDURE IF EXISTS ddbba.sp_generar_tipos_envio;
DROP PROCEDURE IF EXISTS ddbba.sp_generar_envios_expensas;
DROP PROCEDURE IF EXISTS ddbba.sp_generar_estado_financiero;
DROP PROCEDURE IF EXISTS ddbba.sp_generar_gastos_extraordinarios;
DROP PROCEDURE IF EXISTS ddbba.sp_generar_cuotas;
DROP PROCEDURE IF EXISTS ddbba.sp_generar_pagos;
DROP PROCEDURE IF EXISTS ddbba.sp_generar_vencimientos_expensas;
DROP PROCEDURE IF EXISTS ddbba.sp_generar_detalle_expensas_por_uf;
DROP PROCEDURE IF EXISTS ddbba.sp_importar_consorcios;
DROP PROCEDURE IF EXISTS ddbba.sp_importar_proveedores;
DROP PROCEDURE IF EXISTS ddbba.sp_importar_pagos;
DROP PROCEDURE IF EXISTS ddbba.sp_importar_uf_por_consorcios;
DROP PROCEDURE IF EXISTS ddbba.sp_importar_inquilinos_propietarios;
DROP PROCEDURE IF EXISTS ddbba.sp_importar_servicios;
DROP PROCEDURE IF EXISTS ddbba.sp_relacionar_inquilinos_uf;
DROP PROCEDURE IF EXISTS ddbba.sp_relacionar_pagos;
DROP PROCEDURE IF EXISTS ddbba.sp_actualizar_prorrateo;
GO

/*--- Eliminación de tablas ---*/
DROP TABLE IF EXISTS ddbba.detalle_expensas_por_uf;
DROP TABLE IF EXISTS ddbba.estado_financiero;
DROP TABLE IF EXISTS ddbba.pago;
DROP TABLE IF EXISTS ddbba.envio_expensa;
DROP TABLE IF EXISTS ddbba.cuotas;
DROP TABLE IF EXISTS ddbba.gasto_extraordinario;
DROP TABLE IF EXISTS ddbba.gastos_ordinarios;
DROP TABLE IF EXISTS ddbba.expensa;
DROP TABLE IF EXISTS ddbba.rol;
DROP TABLE IF EXISTS ddbba.unidad_funcional;
DROP TABLE IF EXISTS ddbba.tipo_envio;
DROP TABLE IF EXISTS ddbba.tipo_gasto;
DROP TABLE IF EXISTS ddbba.persona;
DROP TABLE IF EXISTS ddbba.proveedores;
DROP TABLE IF EXISTS ddbba.consorcio;
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

/*--- Creación de esquema ---*/
CREATE SCHEMA ddbba;
GO

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  FIN DE CREACION DE BASE DE DATOS <<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  CREACION DE TABLAS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
CREATE TABLE ddbba.consorcio (
    id_consorcio INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50),
    metros_cuadrados INT,
    direccion VARCHAR(100),
    cant_UF SMALLINT
);
GO

-- Tabla proveedores
CREATE TABLE ddbba.proveedores (
    id_proveedores INT PRIMARY KEY IDENTITY(1,1),
    tipo_de_gasto VARCHAR(50),
    entidad VARCHAR(100),
    detalle VARCHAR(120) NULL,
    nombre_consorcio VARCHAR(80)
);
GO

-- Tabla persona
CREATE TABLE ddbba.persona (
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
CREATE TABLE ddbba.tipo_gasto (
    id_tipo_gasto INT PRIMARY KEY IDENTITY(1,1),
    detalle VARCHAR(100)
);
GO

-- Tabla tipo_envio
CREATE TABLE ddbba.tipo_envio (
    id_tipo_envio INT PRIMARY KEY IDENTITY(1,1),
    detalle VARCHAR(100)
);
GO

-- Tabla unidad_funcional (PK compuesta)
CREATE TABLE ddbba.unidad_funcional (
    id_unidad_funcional INT NOT NULL,
    id_consorcio INT NOT NULL,
    metros_cuadrados INT,
    piso VARCHAR(2),
    departamento VARCHAR(10),
    cochera BIT DEFAULT 0,
    baulera BIT DEFAULT 0,
    coeficiente FLOAT,
    saldo_anterior decimal(12,3) DEFAULT 0.00,
    cbu VARCHAR(30),
    prorrateo FLOAT DEFAULT 0,
    CONSTRAINT PK_unidad_funcional PRIMARY KEY (id_unidad_funcional, id_consorcio),
    FOREIGN KEY (id_consorcio) REFERENCES ddbba.consorcio(id_consorcio) ON DELETE CASCADE
);
GO

-- Tabla rol
CREATE TABLE ddbba.rol (
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
        REFERENCES ddbba.unidad_funcional(id_unidad_funcional, id_consorcio) ON DELETE CASCADE,
    FOREIGN KEY (nro_documento, tipo_documento) 
        REFERENCES ddbba.persona(nro_documento, tipo_documento) ON DELETE CASCADE
);
GO

-- Tabla expensa
CREATE TABLE ddbba.expensa (
    id_expensa INT PRIMARY KEY IDENTITY(1,1),
    id_consorcio INT NOT NULL,
    fecha_emision DATE,
    primer_vencimiento DATE,
    segundo_vencimiento DATE,
    FOREIGN KEY (id_consorcio) REFERENCES ddbba.consorcio(id_consorcio) ON DELETE CASCADE
);
GO

-- Tabla gastos_ordinarios
CREATE TABLE ddbba.gastos_ordinarios (
    id_gasto_ordinario INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT,
    id_tipo_gasto INT,
    detalle VARCHAR(200),
    nro_factura VARCHAR(50),
    importe decimal(12,3),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa) ON DELETE CASCADE,
    FOREIGN KEY (id_tipo_gasto) REFERENCES ddbba.tipo_gasto(id_tipo_gasto)
);
GO

-- Tabla gasto_extraordinario
CREATE TABLE ddbba.gasto_extraordinario (
    id_gasto_extraordinario INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT,
    detalle VARCHAR(200),
    total_cuotas INT DEFAULT 1,
    pago_en_cuotas BIT DEFAULT 0,
    importe_total decimal(12,3),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa) ON DELETE CASCADE
);
GO

-- Tabla cuotas
CREATE TABLE ddbba.cuotas (
    id_gasto_extraordinario INT,
    nro_cuota INT,
    PRIMARY KEY (id_gasto_extraordinario, nro_cuota),
    FOREIGN KEY (id_gasto_extraordinario) REFERENCES ddbba.gasto_extraordinario(id_gasto_extraordinario) ON DELETE CASCADE
);
GO

-- Tabla envio_expensa
CREATE TABLE ddbba.envio_expensa (
    id_envio INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT NOT NULL,
    id_unidad_funcional INT NOT NULL,
    id_consorcio INT NOT NULL,
    id_tipo_envio INT NOT NULL,
    destinatario_nro_documento BIGINT,
    destinatario_tipo_documento VARCHAR(10),
    fecha_envio DATETIME,
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa) ON DELETE CASCADE,
    FOREIGN KEY (id_unidad_funcional, id_consorcio) REFERENCES ddbba.unidad_funcional(id_unidad_funcional, id_consorcio),
    FOREIGN KEY (id_tipo_envio) REFERENCES ddbba.tipo_envio(id_tipo_envio),
    FOREIGN KEY (destinatario_nro_documento, destinatario_tipo_documento) 
        REFERENCES ddbba.persona(nro_documento, tipo_documento) ON DELETE CASCADE
);
GO

-- Tabla pago

CREATE TABLE ddbba.pago (
    id_pago INT PRIMARY KEY,
    id_unidad_funcional INT,
    id_consorcio INT,
    id_expensa INT,
    fecha_pago DATETIME,
    monto decimal(12,3),
    cbu_origen VARCHAR(30),
    estado VARCHAR(30),
    FOREIGN KEY (id_unidad_funcional, id_consorcio) REFERENCES ddbba.unidad_funcional(id_unidad_funcional, id_consorcio) ON DELETE CASCADE,
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa)
);
GO

-- Tabla estado_financiero
CREATE TABLE ddbba.estado_financiero (
    id_expensa INT PRIMARY KEY,
    saldo_anterior decimal(12,3),
    ingresos_en_termino decimal(12,3),
    ingresos_adelantados decimal(12,3),
    ingresos_adeudados decimal(12,3),
    egresos_del_mes decimal(12,3),
    saldo_cierre decimal(12,3),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa) ON DELETE CASCADE
);
GO

-- Tabla detalle_expensas_por_uf
CREATE TABLE ddbba.detalle_expensas_por_uf (
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
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa) ON DELETE CASCADE,
    FOREIGN KEY (id_unidad_funcional, id_consorcio) REFERENCES ddbba.unidad_funcional(id_unidad_funcional, id_consorcio)
);
GO

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  FIN DE CREACION DE TABLAS  <<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  CREACION DE FUNCIONES <<<<<<<<<<<<<<<<<<<<<<<<<<*/
CREATE OR ALTER FUNCTION ddbba.fn_normalizar_monto (@valor VARCHAR(50))
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
    SET @resultado = ddbba.fn_limpiar_espacios(LTRIM(RTRIM(ISNULL(@valor, '')))); --Borra espacios izq, der y entre medio
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


CREATE OR ALTER FUNCTION ddbba.fn_limpiar_espacios (@valor VARCHAR(MAX))
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