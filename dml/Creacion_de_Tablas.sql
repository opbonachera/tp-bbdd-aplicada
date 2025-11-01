--Para dropear
DROP TABLE ddbba.detalle_expensas_por_uf 
DROP TABLE ddbba.estado_financiero 
DROP TABLE ddbba.pago
DROP TABLE ddbba.envio_expensa 
DROP TABLE ddbba.cuotas 
DROP TABLE ddbba.gasto_extraordinario
DROP TABLE ddbba.gastos_ordinarios 
DROP TABLE ddbba.expensa
DROP TABLE ddbba.rol
DROP TABLE ddbba.unidad_funcional 
DROP TABLE ddbba.tipo_envio
DROP TABLE ddbba.tipo_gasto 
DROP TABLE ddbba.persona
DROP TABLE ddbba.Proveedores
DROP TABLE  ddbba.consorcio 
--
create database "consorcios"
go

use "consorcios"
go 

create schema ddbba
go 

-- Tabla de consorcio
CREATE TABLE  ddbba.consorcio (
    id_consorcio INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(255),
    metros_cuadrados INT,
    direccion VARCHAR(255),
    cant_UF smallint,
);
go

--Tabla proveedores
CREATE TABLE ddbba.Proveedores(
	id_proveedores INT PRIMARY KEY IDENTITY(1,1),
	tipo_de_gasto VARCHAR(50),
	descripcion VARCHAR (100),
	detalle VARCHAR(100) NULL,
	nombre_consorcio VARCHAR (255),
);

-- Tabla de persona
CREATE TABLE ddbba.persona (
    nro_documento BIGINT,
    tipo_documento VARCHAR(10),
    nombre VARCHAR(255),
    mail VARCHAR(255) UNIQUE,
    telefono VARCHAR(25),
    PRIMARY KEY (nro_documento, tipo_documento)
);
go
-- Tabla de Tipos de Gasto
CREATE TABLE ddbba.tipo_gasto (
    id_tipo_gasto INT PRIMARY KEY IDENTITY(1,1),
    detalle VARCHAR(255) 
);
go

-- Tabla de Tipos de Envío
CREATE TABLE ddbba.tipo_envio (
    id_tipo_envio INT PRIMARY KEY IDENTITY(1,1),
    detalle VARCHAR(100)
);
go

-- Tabla de Unidades Funcionales (depende de consorcio)
CREATE TABLE ddbba.unidad_funcional (
    id_unidad_funcional INT PRIMARY KEY IDENTITY(1,1),
    id_consorcio INT,
    metros_cuadrados INT,
    piso INT,
    departamento VARCHAR(10),
    cochera BIT DEFAULT 0,
    baulera BIT DEFAULT 0,
	coeficiente FLOAT,
    saldo_anterior DECIMAL(12, 2) DEFAULT 0.00,
    cbu VARCHAR(22) UNIQUE,
    prorrateo FLOAT DEFAULT 0,
    FOREIGN KEY (id_consorcio) REFERENCES ddbba.consorcio(id_consorcio)
        ON DELETE CASCADE 

);
go

-- Tabla de rol (depende de unidad_funcional y persona)
CREATE TABLE ddbba.rol (
    id_rol INT PRIMARY KEY IDENTITY(1,1),
    id_unidad_funcional INT,
    nro_documento BIGINT,
    tipo_documento VARCHAR(10),
    nombre_rol VARCHAR(50),
    activo BIT DEFAULT 1,
    fecha_inicio DATE,
    fecha_fin DATE,
    FOREIGN KEY (id_unidad_funcional) REFERENCES ddbba.unidad_funcional(id_unidad_funcional)
        ON DELETE CASCADE,
    FOREIGN KEY (nro_documento, tipo_documento) REFERENCES ddbba.persona(nro_documento, tipo_documento)
        ON DELETE CASCADE 
);
go

-- Tabla de expensa (depende de consorcio)
CREATE TABLE ddbba.expensa (
    id_expensa INT PRIMARY KEY IDENTITY(1,1),
    id_consorcio INT,
    fecha_emision DATE,
    primer_vencimiento DATE,
    segundo_vencimiento DATE,
    FOREIGN KEY (id_consorcio) REFERENCES ddbba.consorcio(id_consorcio)
        ON DELETE CASCADE -- AÑADIDO
);
go 

-- Tabla de Gastos Ordinarios (depende de expensa y tipo_gasto)
CREATE TABLE ddbba.gastos_ordinarios (
    id_gasto_ordinario INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT,
    id_tipo_gasto INT,
    detalle VARCHAR(255),
    nro_factura VARCHAR(50),
    importe DECIMAL(12, 2),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa)
        ON DELETE CASCADE, 
    FOREIGN KEY (id_tipo_gasto) REFERENCES ddbba.tipo_gasto(id_tipo_gasto)
);
go

-- Tabla de Gastos Extraordinarios (depende de expensa)
CREATE TABLE ddbba.gasto_extraordinario (
    id_gasto_extraordinario INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT,
    detalle VARCHAR(255) ,
    total_cuotas INT DEFAULT 1,
    pago_en_cuotas BIT DEFAULT 0,
    importe_total DECIMAL(12, 2),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa)
        ON DELETE CASCADE -- AÑADIDO
);
go

-- Tabla de Cuotas (depende de gastos_extraordinarios)
CREATE TABLE ddbba.cuotas (
    id_gasto_extraordinario INT,
    nro_cuota INT,
    PRIMARY KEY (id_gasto_extraordinario, nro_cuota),
    FOREIGN KEY (id_gasto_extraordinario) REFERENCES ddbba.gasto_extraordinario(id_gasto_extraordinario)
        ON DELETE CASCADE 
);
go

-- Tabla de Envíos de Expensa (depende de multiples tablas)

CREATE TABLE ddbba.envio_expensa (
    id_envio INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT NOT NULL,
    id_unidad_funcional INT NOT NULL,
    id_tipo_envio INT NOT NULL,
    destinatario_nro_documento BIGINT,
    destinatario_tipo_documento VARCHAR(10),
    fecha_envio DATETIME,
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa)
        ON DELETE CASCADE,
    FOREIGN KEY (id_unidad_funcional) REFERENCES ddbba.unidad_funcional(id_unidad_funcional),
    FOREIGN KEY (id_tipo_envio) REFERENCES ddbba.tipo_envio(id_tipo_envio),
    FOREIGN KEY (destinatario_nro_documento, destinatario_tipo_documento) REFERENCES ddbba.persona(nro_documento, tipo_documento)
        ON DELETE CASCADE 
);
go

-- Tabla de pago (depende de unidad_funcional y expensa)

CREATE TABLE ddbba.pago (
    id_pago INT PRIMARY KEY,
    id_unidad_funcional INT,
    id_expensa INT,
    fecha_pago DATETIME,
    monto DECIMAL(12, 2),
    cbu_origen VARCHAR(22),
    estado VARCHAR(50),
    FOREIGN KEY (id_unidad_funcional) REFERENCES ddbba.unidad_funcional(id_unidad_funcional)
        ON DELETE CASCADE, 
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa)
    
);
go

-- Tabla de Estado Financiero (depende de expensa)
CREATE TABLE ddbba.estado_financiero (
    id_expensa INT PRIMARY KEY,
    saldo_anterior DECIMAL(12, 2),
    ingresos_en_termino DECIMAL(12, 2),
    ingresos_adelantados DECIMAL(12, 2),
    ingresos_adeudados DECIMAL(12, 2),
    egresos_del_mes DECIMAL(12, 2),
    saldo_cierre DECIMAL(12, 2),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa)
        ON DELETE CASCADE 
);
go

CREATE TABLE ddbba.detalle_expensas_por_uf (
    id_detalle INT NOT NULL,
    id_expensa INT NOT NULL,
    id_uf INT,
    gastos_ordinarios INT,
    gastos_extraordinarios INT,
    deuda INT,
    interes_mora INT,
    monto_total INT,
    PRIMARY KEY (id_detalle, id_expensa, id_uf),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa)
        ON DELETE CASCADE, 
    FOREIGN KEY (id_uf) REFERENCES ddbba.unidad_funcional(id_unidad_funcional)
);