# Altos de Saint Just

La administración de consorcios Altos de Saint Just solicita generar un sistema centralizado
para poder generar las expensas de cada consorcio de manera automática y con el menor
ingreso de datos posible.


## Integrantes del equipo


- Arcón Wogelman, Nazareno —  Usuario: [NazarenoAW](https://github.com/NazarenoAW)
- Arriola Santiago —  Usuario: [Santiagoiiezequiel](https://github.com/Santiagoiiezequiel)
- Benitez Jimena —  Usuario: [jimebenitez-cyber](https://github.com/jimebenitez-cyber)
- Bonachera Ornella —  Usuario: [opbonachera](https://github.com/opbonachera)
- Perez, Olivia Constanza —  Usuario: [perezolivia](https://github.com/perezolivia)
- Guardia Gabriel —  Usuario: [roqueguardia](https://github.com/roqueguardia)

## Nomenclatura y Estándares de Desarrollo

Para garantizar la coherencia y mantenibilidad del código T-SQL, se definieron las siguientes reglas de nomenclatura aplicadas a todos los objetos de la base de datos.

### 1. Convenciones Generales

* **Idioma:** Español (se evita el uso de ñ y tildes en nombres de objetos para compatibilidad).
* **Case:** `snake_case` (minúsculas separadas por guiones bajos).
* **Singular/Plural:**
    * **Tablas:** Nombres en **singular** (ej. `unidad_funcional`, `pago`).
    * **Esquemas:** Sustantivos en **plural** o colectivos (ej. `consorcios`, `finanzas`).

### 2. Prefijos y Definiciones

| Objeto de Base de Datos | Prefijo / Formato | Descripción | Ejemplo |
| :--- | :--- | :--- | :--- |
| **Primary Key (PK)** | `id_` + [entidad] | Identificador único numérico o compuesto. | `id_consorcio` |
| **Foreign Key (FK)** | `id_` + [entidad] | Referencia a la PK de otra tabla. | `id_expensa` |
| **Stored Procedures** | `sp_` + [verbo] | Procedimientos almacenados para lógica de negocio. | `sp_generar_cuotas` |
| **Funciones** | `fn_` + [utilidad] | Funciones escalares o de tabla para transformación de datos. | `fn_normalizar_monto` |
| **Índices** | `IX_` + [tabla] + [cols] | Índices no agrupados para optimización de consultas. | `IX_pago_fecha` |
| **Variables** | `@` + [nombre] | Variables locales y parámetros (camelCase o snake_case). | `@fecha_hasta` |

### 3. Organización de Esquemas

La base de datos se estructura en esquemas lógicos para separar dominios de negocio:

| Esquema | Propósito | Tablas Principales |
| :--- | :--- | :--- |
| **`consorcios`** | Datos estructurales de los inmuebles. | `consorcio`, `unidad_funcional` |
| **`personas`** | Gestión de entidades legales y físicas. | `persona`, `rol`, `proveedor` |
| **`finanzas`** | Núcleo transaccional y contable. | `pago`, `expensa`, `gasto_ordinario`, `cuota` |
| **`gestion`** | Procesos administrativos y comunicación. | `envio_expensa`, `tipo_envio` |
| **`datos`** | Capa de reporting y análisis de negocio. | (Contiene solo Stored Procedures de reporte) |
| **`utils`** | Herramientas de sistema e importación. | (Scripts de carga masiva y funciones auxiliares) |

## Organización del proyecto
El proyecto se encuentra organizado según las 7 entregas requeridas para la aprobación del trabajo práctico. 

### Entrega 1
Se estableció un escenario hipotético en el que el cliente dispone de un servidor con determinadas capacidades y el equipo debió analizar si estas eran suficientes para alojar el motor de base de datos OracleDB.

### Entrega 2
Se analizó la posibilidad de alojar la base de datos en la nube, contando con 3 alternativas: GCP, AWS y ??? 

### Entrega 3
Se diseñó el DER para almacenar la información requerida para la gestión de las expensas de un consorcio. 

### Entrega 4
Se generó el documento de instalación para la base de datos. 

### Entrega 5
Se realizó la importación de los archivos que contienen la información relacionada a los consorcios y las unidades funcionales.

### Entrega 6 
Se generó una serie de reportes requeridos por la consigna. 

### Entrega 7
Se establecieron políticas de seguridad como la creación de usuarios y roles específicos, así como también se realizó la encriptación de datos personales y/o sensibles.


## Documentación
La documentación detallada del proyecto se encuentra en el siguiente [link]().
## Installation
Para trabajar con este proyecto se necesita contar con los siguientes componentes instalados:

#### 1. SQL Server
Se requiere una instancia de Microsoft SQL Server (versión 2016 o superior).
Se recomienda la versión Express (gratuita, con limitaciones de recursos pero útil para un pequeño proyecto)

Descargar: https://www.microsoft.com/en-us/sql-server/sql-server-downloads

#### 2. SQL Server Management Studio (SSMS)

Cliente gráfico utilizado para administrar la base de datos, ejecutar scripts y gestionar objetos SQL Versión recomendada: SSMS 19.x o superior

Descargar: https://learn.microsoft.com/sql/ssms/download-sql-server-management-studio

#### 3. Microsoft Access Database Engine (ACE OLEDB)
Necesario para la importación de archivos Excel (.xlsx, .xls) desde SQL Server mediante OPENROWSET u OPENQUERY. Debe coincidir la instalación de ACE con la arquitectura de SQL Server (32 o 64 bits).

Descargar: https://www.microsoft.com/en-us/download/details.aspx?id=54920

#### 4. Permisos necesarios
Asegurate de que el usuario SQL utilizado tenga permisos para:

Crear bases de datos.
Crear tablas, vistas, SPs y funciones.

Ejecutar OPENROWSET y BULK INSERT.
