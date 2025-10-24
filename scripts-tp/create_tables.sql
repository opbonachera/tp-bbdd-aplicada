

create database "consorcios"
go

use "consorcios"
go 

create schema ddbba
go 

-- Tabla de consorcio
CREATE TABLE ddbba.consorcio (
    id_consorcio INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(255) NOT NULL,
    metros_cuadrados INT,
    direccion VARCHAR(255) NOT NULL,
    cbu VARCHAR(22) UNIQUE
);
go

-- Tabla de persona
CREATE TABLE ddbba.persona (
    nro_documento BIGINT NOT NULL,
    tipo_documento VARCHAR(10) NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    mail VARCHAR(255) UNIQUE,
    telefono VARCHAR(25),
    PRIMARY KEY (nro_documento, tipo_documento)
);
go
-- Tabla de Tipos de Gasto
CREATE TABLE ddbba.tipo_gasto (
    id_tipo_gasto INT PRIMARY KEY IDENTITY(1,1),
    detalle VARCHAR(255) NOT NULL UNIQUE
);
go

-- Tabla de Tipos de Envío
CREATE TABLE ddbba.tipo_envio (
    id_tipo_envio INT PRIMARY KEY IDENTITY(1,1),
    detalle VARCHAR(100) NOT NULL UNIQUE
);
go

-- Tabla de Unidades Funcionales (depende de consorcio)
CREATE TABLE ddbba.unidad_funcional (
    id_unidad_funcional INT PRIMARY KEY IDENTITY(1,1),
    id_consorcio INT NOT NULL,
    metros_cuadrados INT,
    piso INT,
    departamento VARCHAR(10),
    cochera BIT DEFAULT 0,
    baulera BIT DEFAULT 0,
    saldo_anterior DECIMAL(12, 2) DEFAULT 0.00,
    cbu VARCHAR(22) UNIQUE,
    prorrateo FLOAT,
    FOREIGN KEY (id_consorcio) REFERENCES ddbba.consorcio(id_consorcio)
);
go

-- Tabla de rol (depende de unidad_funcional y persona)
CREATE TABLE ddbba.rol (
    id_rol INT PRIMARY KEY IDENTITY(1,1),
    id_unidad_funcional INT NOT NULL,
    nro_documento BIGINT NOT NULL,
    tipo_documento VARCHAR(10) NOT NULL,
    nombre_rol VARCHAR(50) NOT NULL,
    activo BIT DEFAULT 1,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    FOREIGN KEY (id_unidad_funcional) REFERENCES ddbba.unidad_funcional(id_unidad_funcional),
    FOREIGN KEY (nro_documento, tipo_documento) REFERENCES ddbba.persona(nro_documento, tipo_documento)
);
go

-- Tabla de expensa (depende de consorcio)
CREATE TABLE ddbba.expensa (
    id_expensa INT PRIMARY KEY IDENTITY(1,1),
    id_consorcio INT NOT NULL,
    fecha_emision DATE NOT NULL,
    primer_vencimiento DATE NOT NULL,
    segundo_vencimiento DATE,
    FOREIGN KEY (id_consorcio) REFERENCES ddbba.consorcio(id_consorcio)
);
go 

-- Tabla de Gastos Ordinarios (depende de expensa y tipo_gasto)
CREATE TABLE ddbba.gastos_ordinarios (
    id_gasto_ordinario INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT NOT NULL,
    id_tipo_gasto INT NOT NULL,
    detalle VARCHAR(255),
    nro_factura VARCHAR(50),
    importe DECIMAL(12, 2) NOT NULL,
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa),
    FOREIGN KEY (id_tipo_gasto) REFERENCES ddbba.tipo_gasto(id_tipo_gasto)
);
go

-- Tabla de Gastos Extraordinarios (depende de expensa)
CREATE TABLE ddbba.gasto_extraordinario (
    id_gasto_extraordinario INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT NOT NULL,
    detalle VARCHAR(255) NOT NULL,
    total_cuotas INT DEFAULT 1,
    pago_en_cuotas BIT DEFAULT 0,
    importe_total DECIMAL(12, 2) NOT NULL,
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa)
);
go

-- Tabla de Cuotas (depende de gastos_extraordinarios)
CREATE TABLE ddbba.cuotas (
    id_gasto_extraordinario INT NOT NULL,
    nro_cuota INT NOT NULL,
    PRIMARY KEY (id_gasto_extraordinario, nro_cuota),
    FOREIGN KEY (id_gasto_extraordinario) REFERENCES ddbba.gasto_extraordinario(id_gasto_extraordinario)
);
go

-- Tabla de Envíos de Expensa (depende de multiples tablas)
CREATE TABLE ddbba.envio_expensa (
    id_envio INT PRIMARY KEY IDENTITY(1,1),
    id_expensa INT NOT NULL,
    id_unidad_funcional INT NOT NULL,
    id_tipo_envio INT NOT NULL,
    destinatario_nro_documento BIGINT NOT NULL,
    destinatario_tipo_documento VARCHAR(10) NOT NULL,
    fecha_envio DATETIME NOT NULL,
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa),
    FOREIGN KEY (id_unidad_funcional) REFERENCES ddbba.unidad_funcional(id_unidad_funcional),
    FOREIGN KEY (id_tipo_envio) REFERENCES ddbba.tipo_envio(id_tipo_envio),
    FOREIGN KEY (destinatario_nro_documento, destinatario_tipo_documento) REFERENCES ddbba.persona(nro_documento, tipo_documento)
);
go

-- Tabla de pago (depende de unidad_funcional y expensa)
CREATE TABLE ddbba.pago (
    id_pago INT PRIMARY KEY IDENTITY(1,1),
    id_unidad_funcional INT NOT NULL,
    id_expensa INT NOT NULL,
    fecha_pago DATETIME NOT NULL,
    monto DECIMAL(12, 2) NOT NULL,
    cbu_origen VARCHAR(22),
    estado VARCHAR(50) NOT NULL,
    FOREIGN KEY (id_unidad_funcional) REFERENCES ddbba.unidad_funcional(id_unidad_funcional),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa)
);
go

-- Tabla de Estado Financiero (depende de expensa)
CREATE TABLE ddbba.estado_financiero (
    id_expensa INT PRIMARY KEY,
    saldo_anterior DECIMAL(12, 2) NOT NULL,
    ingresos_en_termino DECIMAL(12, 2) NOT NULL,
    ingresos_adelantados DECIMAL(12, 2) NOT NULL,
    ingresos_adeudados DECIMAL(12, 2) NOT NULL,
    egresos_del_mes DECIMAL(12, 2) NOT NULL,
    saldo_cierre DECIMAL(12, 2) NOT NULL,
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa)
);
go

-- Tabla de Detalle de Expensa por UF (depende de expensa y unidad_funcional)
CREATE TABLE detalle_expensas_por_uf (
    id_detalle INT NOT NULL,
    id_expensa INT NOT NULL,
    id_uf INT NOT NULL,
    gastos_ordinarios INT,
    gastos_extraordinarios INT,
    deuda INT,
    interes_mora INT,
    monto_total INT,
    PRIMARY KEY (id_detalle, id_expensa, id_uf),
    FOREIGN KEY (id_expensa) REFERENCES ddbba.expensa(id_expensa),
    FOREIGN KEY (id_uf) REFERENCES ddbba.unidad_funcional(id_unidad_funcional)
);
