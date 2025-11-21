/*---------------------------------------------------------
 Materia:     Base de datos aplicada. 
 Grupo:       1
 Comision:    5600
 Fecha:       2025-01-01
 Descripcion: Creacion de objetos relacionados a la seguridad del cifrado.
              NOTA: para que funcione el script correctamente se debe respetar el orden de la
              creaci�n indicado por los bloques. 
              1. Seleccionar y ejecutar bloque 1
              2. Ejecutar SP creado en el bloque 1
              3. Seleccionar y ejecutar bloque 2
              4. Seleccionar y ejecutar bloque 3
 Integrantes: Arc�n Wogelman, Nazareno � 44792096
              Arriola Santiago � 41743980 
              Bonachera Ornella � 46119546
              Benitez Jimena � 46097948
              Guardia Gabriel � 42364065
              Perez, Olivia Constanza � 46641730
----------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>>>>>> INICIO DEL SCRIPT  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */
/*>>>>>>>> CREACION DE SP, VISTAS Y TRIGGERS PARA LA ENCRIPTACION DE DATOS  <<<<<<<<<<<<*/

/*>>>>>>>>>>>>>>>>>>>>>>>> INICIO BLOQUE 1  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */
/* --- Agrega las columnas extra para los datos cifrados---*/
CREATE OR ALTER PROCEDURE seguridad.sp_alter_table
AS
BEGIN
--primero agrego una columna extra a la tabla que cifre todos los datos que ya estan en la tabla
	EXEC ('ALTER TABLE personas.persona ADD cbu_cifrado VARBINARY(MAX),
		 telefono_cifrado VARBINARY(MAX),mail_cifrado VARBINARY(MAX)');
	EXEC('ALTER TABLE finanzas.pago ADD cbu_cifrado VARBINARY(MAX)');
    EXEC('ALTER TABLE consorcios.unidad_funcional ADD cbu_cifrado VARBINARY(MAX)');
END;
GO
/*>>>>>>>>>>>>>>>>>>>>>>>> FIN BLOQUE 1  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */

/*>>>>>>>>>>>>>>>>>>>>>>>> INICIO BLOQUE 2  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */
/* --- Para que funcione correctamente la creacion de estos objetos se debe ejecutar el sp anterior---*/
-- exec seguridad.sp_alter_table


-- Cifrar tablas
CREATE OR ALTER PROCEDURE seguridad.sp_cifrado_tablas
AS
BEGIN
    SET NOCOUNT ON;

    -- Verifico si existen datos sin cifrar en alguna tabla
    IF EXISTS (
        SELECT 1 FROM personas.persona
        WHERE mail IS NOT NULL OR telefono IS NOT NULL OR cbu IS NOT NULL
    )
    OR EXISTS (
        SELECT 1 FROM finanzas.pago
        WHERE cbu_origen IS NOT NULL
    )
    OR EXISTS (
        SELECT 1 FROM consorcios.unidad_funcional
        WHERE cbu IS NOT NULL
    )
    BEGIN
        PRINT 'Iniciando proceso de cifrado...';

        -- Tabla persona
        UPDATE personas.persona
        SET 
            cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(20), cbu)),
            telefono_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(20), telefono)),
            mail_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(100), mail))
        WHERE mail IS NOT NULL OR telefono IS NOT NULL OR cbu IS NOT NULL;

        -- Tabla pago
        UPDATE finanzas.pago
        SET cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(50), cbu_origen))
        WHERE cbu_origen IS NOT NULL;

        -- Tabla unidad_funcional
        UPDATE consorcios.unidad_funcional
        SET cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(50), cbu))
        WHERE cbu IS NOT NULL;

        -- Limpieza de datos en texto plano
        UPDATE personas.persona
        SET cbu = NULL, mail = NULL, telefono = NULL;

        UPDATE finanzas.pago
        SET cbu_origen = NULL;

        UPDATE consorcios.unidad_funcional
        SET cbu = NULL;

        PRINT 'Datos cifrados correctamente.';
    END
    ELSE
    BEGIN
        PRINT 'Todos los datos ya se encuentran cifrados';
    END
END;
GO

/* --- DESENCRIPTA DATOS DE LA TABLA DE PERSONAS--- */
--tabla personas
CREATE OR ALTER VIEW seguridad.vw_persona
AS
SELECT 
    nro_documento,
	tipo_documento,
    nombre,
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', mail_cifrado)) AS mail,
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', telefono_cifrado)) AS telefono,
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', cbu_cifrado)) AS cbu
FROM personas.persona;
GO

/* --- DESENCRIPTA DATOS DE LA TABLA DE PAGOS--- */
CREATE OR ALTER VIEW seguridad.vw_pago
AS
SELECT 
    id_pago,
	id_unidad_funcional,
    id_consorcio,
    id_expensa,
    fecha_pago,
    monto,
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', cbu_cifrado)) AS cbu_origen,
    estado
FROM finanzas.pago;
GO

/* --- DESENCRIPTA DATOS DE LA TABLA DE UNIDAD FUNCIONAL --- */
CREATE OR ALTER VIEW seguridad.vw_uf
AS
SELECT 
    id_unidad_funcional,
    id_consorcio,
    metros_cuadrados,
    piso,
    departamento,
    cochera,
    baulera,
    coeficiente,
    saldo_anterior,
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', cbu_cifrado)) AS cbu,
    prorrateo
FROM consorcios.unidad_funcional;
GO

/* --- ENCRIPTA LA INSERCION DE DATOS PERSONALES EN TABLA DE PERSONAS --- */
CREATE OR ALTER TRIGGER personas.trg_cifrar_persona
ON personas.persona
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET 
        p.mail_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(NVARCHAR(100), i.mail)),
        p.telefono_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(NVARCHAR(100), i.telefono)),
        p.cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(NVARCHAR(100), i.cbu))
    FROM personas.persona p
    INNER JOIN inserted i ON p.tipo_documento = i.tipo_documento 
							and p.nro_documento=i.nro_documento;


	UPDATE p
	SET
		p.mail=NULL,
		p.telefono=NULL,
		p.cbu= NULL
	FROM personas.persona p
    INNER JOIN inserted i ON p.tipo_documento = i.tipo_documento 
							and p.nro_documento=i.nro_documento;
END;
GO

/* --- ENCRIPTA LA INSERCION DE DATOS PERSONALES EN TABLA DE PAGOS --- */
CREATE OR ALTER TRIGGER finanzas.trg_cifrar_pago
ON finanzas.pago
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE p
    SET p.cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(100), i.cbu_origen))
    FROM finanzas.pago p
    INNER JOIN inserted i ON p.id_pago = i.id_pago;

	UPDATE p
	SET p.cbu_origen=NULL
	FROM finanzas.pago p
    INNER JOIN inserted i ON p.id_pago = i.id_pago;
END;
GO
/* --- ENCRIPTA LA INSERCION DE DATOS PERSONALES EN TABLA DE UNIDAD FUNCIONAL --- */
CREATE OR ALTER TRIGGER consorcios.trg_cifrar_uf
ON consorcios.unidad_funcional
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE uf
    SET uf.cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(100), i.cbu))
    FROM consorcios.unidad_funcional uf
    INNER JOIN inserted i ON uf.id_unidad_funcional = i.id_unidad_funcional;

	UPDATE uf
	SET
	uf.cbu=NULL
	FROM consorcios.unidad_funcional uf
    INNER JOIN inserted i ON uf.id_unidad_funcional = i.id_unidad_funcional;
END;
GO
/*>>>>>>>>>>>>>>>>>>>>>>>> FIN BLOQUE 2  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */
/*>>>>>>>>>>>>>>>>>>>>>>>> INICIO BLOQUE 3 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


/*>>>>>>>> FIN DE CREACION DE SP, VISTAS Y TRIGGERS PARA LA ENCRIPTACION DE DATOS  <<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>> CREACION DE LOGINS, USUARIOS Y ROLES  <<<<<<<<<<<<<<<<<<<<<<<<*/

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
-- ASIGNACION DE USUARIOS A ROLES
---------------------------------------------------------------
ALTER ROLE rol_administrativo_general ADD MEMBER usuario1;
ALTER ROLE rol_administrativo_operativo ADD MEMBER usuario2;
ALTER ROLE rol_administrativo_bancario ADD MEMBER usuario3;
ALTER ROLE rol_sistemas ADD MEMBER usuario4;

-- Un usuario en m?s de un rol
ALTER ROLE rol_administrativo_general ADD MEMBER usuario3;
GO


---------------------------------------------------------------
-- ASIGNACION DE PERMISOS A ROLES
---------------------------------------------------------------

-- Permisos sobre tabla unidad_funcional
GRANT INSERT, DELETE, UPDATE, SELECT 
ON consorcios.unidad_funcional 
TO rol_administrativo_general, rol_administrativo_operativo;
GO

-- Permisos sobre tabla de pagos
GRANT INSERT, DELETE, UPDATE, SELECT 
ON finanzas.pagos
TO rol_administrativo_bancario
GO

-- Procedimientos de mantenimiento
GRANT EXECUTE ON OBJECT::seguridad.sp_relacionar_inquilinos_uf 
TO rol_administrativo_general, rol_administrativo_operativo;

GRANT EXECUTE ON OBJECT::seguridad.sp_importar_uf_por_consorcios 
TO rol_administrativo_general, rol_administrativo_operativo;
GO

-- Reportes disponibles para todos los roles
GRANT EXECUTE ON OBJECT::seguridad.sp_reporte_1 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::seguridad.sp_reporte_2 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::seguridad.sp_reporte_3 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::seguridad.sp_reporte_4 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::seguridad.sp_reporte_5 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;

GRANT EXECUTE ON OBJECT::seguridad.sp_reporte_6 
TO rol_administrativo_general, rol_administrativo_bancario, rol_administrativo_operativo, rol_sistemas;
GO


/*>>>>>>>>>>>>>>>> FIN DE CREACION DE LOGINS, USUARIOS Y ROLES  <<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>> FIN BLOQUE 3 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DEL SCRIPT  <<<<<<<<<<<<<<<<<<<<<<<<<<*/