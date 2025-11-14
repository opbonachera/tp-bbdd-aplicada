/*ENUNCIADO:CREACION DE TABLAS NECESARIAS PARA EL PROYECTO
COMISION:02-5600 
CURSO:3641
NUMERO DE GRUPO : 01
MATERIA: BASE DE DATOS APLICADA
INTEGRANTES:
Bonachera Ornella � 46119546 
Benitez Jimena � 46097948 
Arc�n Wogelman, Nazareno-44792096
Perez, Olivia Constanza � 46641730
Guardia Gabriel � 42364065 
Arriola Santiago � 41743980 
*/



-- Eliminar tablas en orden correcto (respetando dependencias)
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


-- Crear base y esquema
CREATE DATABASE Com5600_Grupo01;
GO
USE Com5600_Grupo01;
GO
CREATE SCHEMA ddbba;
GO

-- Tabla consorcio
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
    descripcion VARCHAR(100),
    detalle VARCHAR(100) NULL,
    nombre_consorcio VARCHAR(100)
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
    piso CHAR(2),
    departamento CHAR(10),
    cochera BIT DEFAULT 0,
    baulera BIT DEFAULT 0,
    coeficiente decimal(5,3),
    saldo_anterior decimal(12,3) DEFAULT 0.00,
    cbu VARCHAR(30),
    prorrateo decimal(5,3) default 0.00,
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