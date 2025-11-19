/*ENUNCIADO:CREACION DE SP , TRIGGERS, VISTAS NECESARIAS PARA LA ENCRIPTACION DE DATOS SENSIBLES
-se consideran como datos sensibles todos los datos que den informacion sobre la persna
-en la tabla persona cifraron el cbu,mail y telefono y en la tbal pago y uf solo el cbu
COMISION:02-5600 
CURSO:3641
NUMERO DE GRUPO : 01
MATERIA: BASE DE DATOS APLICADA
INTEGRANTES:
Bonachera Ornella — 46119546 
Benitez Jimena — 46097948 
Arcón Wogelman, Nazareno-44792096
Perez, Olivia Constanza — 46641730
Guardia Gabriel — 42364065 
Arriola Santiago — 41743980 
*/



--divido el SP en dos ya que sino vamos a tener q hacer todo el sp dinamico
CREATE OR ALTER PROCEDURE ddbba.sp_alter_table
AS
BEGIN
--primero agrego una columna extra a la tabla que cifre todos los datos que ya estan en la tabla
	EXEC ('ALTER TABLE ddbba.persona ADD cbu_cifrado VARBINARY(MAX),
		 telefono_cifrado VARBINARY(MAX),mail_cifrado VARBINARY(MAX)');
	EXEC('ALTER TABLE ddbba.pago ADD cbu_cifrado VARBINARY(MAX)');
    EXEC('ALTER TABLE ddbba.unidad_funcional ADD cbu_cifrado VARBINARY(MAX)');
END;
--para ejecutar el sp
EXEC ddbba.sp_alter_table
GO;

--esto es para cifrar el cbu da la tablas
CREATE OR ALTER PROCEDURE ddbba.sp_cifrado_tablas
AS
BEGIN
    SET NOCOUNT ON;

    -- Verifico si existen datos sin cifrar en alguna tabla
    IF EXISTS (
        SELECT 1 FROM ddbba.persona
        WHERE mail IS NOT NULL OR telefono IS NOT NULL OR cbu IS NOT NULL
    )
    OR EXISTS (
        SELECT 1 FROM ddbba.pago
        WHERE cbu_origen IS NOT NULL
    )
    OR EXISTS (
        SELECT 1 FROM ddbba.unidad_funcional
        WHERE cbu IS NOT NULL
    )
    BEGIN
        PRINT 'Iniciando proceso de cifrado...';

        -- Tabla persona
        UPDATE ddbba.persona
        SET 
            cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(20), cbu)),
            telefono_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(20), telefono)),
            mail_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(100), mail))
        WHERE mail IS NOT NULL OR telefono IS NOT NULL OR cbu IS NOT NULL;

        -- Tabla pago
        UPDATE ddbba.pago
        SET cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(50), cbu_origen))
        WHERE cbu_origen IS NOT NULL;

        -- Tabla unidad_funcional
        UPDATE ddbba.unidad_funcional
        SET cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(50), cbu))
        WHERE cbu IS NOT NULL;

        -- Limpieza de datos en texto plano
        UPDATE ddbba.persona
        SET cbu = NULL, mail = NULL, telefono = NULL;

        UPDATE ddbba.pago
        SET cbu_origen = NULL;

        UPDATE ddbba.unidad_funcional
        SET cbu = NULL;

        PRINT 'Datos cifrados correctamente.';
    END
    ELSE
    BEGIN
        PRINT 'Todos los datos ya se encuentran cifrados';
    END
END;


--para ejecutar el SP
exec ddbba.sp_cifrado_tablas

--para ver las tablas cifradas
SELECT *
FROM ddbba.persona
SELECT *
FROM ddbba.unidad_funcional
SELECT *
FROM ddbba.pago
GO;
--Creo las vistas para vr las tablas decifradas

--tabla personas
CREATE OR ALTER VIEW ddbba.vw_persona
AS
SELECT 
    nro_documento,
	tipo_documento,
    nombre,
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', mail_cifrado)) AS mail,
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', telefono_cifrado)) AS telefono,
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', cbu_cifrado)) AS cbu
FROM ddbba.persona;

--select * from ddbba.vw_persona_
GO;
--tabla de pagos
CREATE OR ALTER VIEW ddbba.vw_pago
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
FROM ddbba.pago;

--select * from ddbba.vw_pago
GO;
-- tabla de unidad funcional
CREATE OR ALTER VIEW ddbba.vw_uf
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
FROM ddbba.unidad_funcional;

--select * from ddbba.vw_uf

-- triggers para cada vez que se inserte o se cambie alguno de los datos sencibles se vuelva a cifrar
GO;
CREATE OR ALTER TRIGGER ddbba.trg_cifrar_persona
ON ddbba.persona
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET 
        p.mail_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(NVARCHAR(100), i.mail)),
        p.telefono_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(NVARCHAR(100), i.telefono)),
        p.cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(NVARCHAR(100), i.cbu))
    FROM ddbba.persona p
    INNER JOIN inserted i ON p.tipo_documento = i.tipo_documento 
							and p.nro_documento=i.nro_documento;


	UPDATE p
	SET
		p.mail=NULL,
		p.telefono=NULL,
		p.cbu= NULL
	FROM ddbba.persona p
    INNER JOIN inserted i ON p.tipo_documento = i.tipo_documento 
							and p.nro_documento=i.nro_documento;
END;

/*INSERT INTO ddbba.persona (nombre,tipo_documento,nro_documento, mail, telefono, cbu)
VALUES ('Jimena Benitez', 'DNI','46097948','jime@example.com', '1122334455', '0170123400000000000001');
select * from ddbba.persona*/



GO;
-- Pago
CREATE OR ALTER TRIGGER ddbba.trg_cifrar_pago
ON ddbba.pago
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(100), i.cbu_origen))
    FROM ddbba.pago p
    INNER JOIN inserted i ON p.id_pago = i.id_pago;

	UPDATE p
	SET p.cbu_origen=NULL
	FROM ddbba.pago p
    INNER JOIN inserted i ON p.id_pago = i.id_pago;
END;


/*INSERT INTO ddbba.pago (id_pago,id_consorcio, id_expensa, id_unidad_funcional, fecha_pago, monto, cbu_origen, estado)
VALUES ( 102,1,1, 1, GETDATE(), 55000, '0170123400000000000002', 'Aprobado');
 select * from ddbba.pago*/

 GO;
-- Unidad Funcional
CREATE OR ALTER TRIGGER ddbba.trg_cifrar_uf
ON ddbba.unidad_funcional
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE uf
    SET uf.cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(100), i.cbu))
    FROM ddbba.unidad_funcional uf
    INNER JOIN inserted i ON uf.id_unidad_funcional = i.id_unidad_funcional;

	UPDATE uf
	SET
	uf.cbu=NULL
	FROM ddbba.unidad_funcional uf
    INNER JOIN inserted i ON uf.id_unidad_funcional = i.id_unidad_funcional;
END;

/*INSERT INTO ddbba.unidad_funcional (id_unidad_funcional,id_consorcio, metros_cuadrados, piso, departamento, cochera, baulera, coeficiente, saldo_anterior, cbu, prorrateo)
VALUES (40,1, 75, 3, 'B', 1, 0, 0.8, 0, '0170123400000000000003', 0.8);
SELECT * FROM ddbba.unidad_funcional*/
