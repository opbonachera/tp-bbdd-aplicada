/*---------------------------------------------------------
 Materia:     Base de datos aplicada. 
 Grupo:       1
 Comision:    5600
 Fecha:       2025-01-01
 Descripcion: Creacion de los procedimientos para generar datos adicionales que
              no estan presentes en los archivos, por ejemplo gastos extraordinarios
              o pagos no asociados.
 Integrantes: Arc�n Wogelman, Nazareno � 44792096
              Arriola Santiago � 41743980 
              Bonachera Ornella � 46119546
              Benitez Jimena � 46097948
              Guardia Gabriel � 42364065
              Perez, Olivia Constanza � 46641730
----------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> INICIO DEL SCRIPT  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
USE "Com5600_Grupo01"
GO

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

-- Cifrar tablas
CREATE OR ALTER PROCEDURE  seguridad.sp_cifrado_tablas
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
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DEL SCRIPT  <<<<<<<<<<<<<<<<<<<<<<<<<<*/