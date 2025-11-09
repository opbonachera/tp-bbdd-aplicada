/*se consideran como datos sensibles todos los datos que den informacion sobre la persona*/
/*solamente tome como dato sensible el cbu de la persona ,ya que ,
nosotros tenemos DNI como PK y para cifrarla tendriamos que borrar la tabla y cambiar la PK y cambiar todas las FK */
/*en la tabla persona cifre el cbu,mail y telefono y en la tbal pago y uf solo el cbu*/

USE consorcios
go

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


--esto es para cifrar los datos de las tres tablas
CREATE OR ALTER PROCEDURE ddbba.sp_cifrado_tablas
AS
BEGIN
--aca cifro los datos que ya estan insertados en la tabla
	--tabla personas
	UPDATE ddbba.persona
	SET cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(20), cbu)),
		telefono_cifrado= ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(20), telefono)),
		mail_cifrado= ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(20), mail));

	--tabla pago
    UPDATE ddbba.pago
    SET cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(50), cbu_origen));

	--tabla uf
    UPDATE ddbba.unidad_funcional
    SET cbu_cifrado = ENCRYPTBYPASSPHRASE('Grupo_1', CONVERT(VARCHAR(50), cbu));

--esto es para eliminar una restringcion que tiene la columna mail
	EXEC('ALTER TABLE ddbba.pesona DROP CONSTRAINT UQ__persona__7A212904BF15E7C8');

--aca elimino todas la columnas que son las que no estan cifradas
	EXEC('ALTER TABLE ddbba.persona DROP COLUMN cbu,telefono,mail');
    EXEC('ALTER TABLE ddbba.pago DROP COLUMN cbu_origen');
    EXEC('ALTER TABLE ddbba.unidad_funcional DROP COLUMN cbu');

--le cambio el nombre a las columnas
	EXEC sp_rename 'ddbba.persona.cbu_cifrado', 'cbu', 'COLUMN';
	EXEC sp_rename 'ddbba.persona.telefono_cifrado', 'telefono', 'COLUMN';
	EXEC sp_rename 'ddbba.persona.mail_cifrado', 'mail', 'COLUMN';
    EXEC sp_rename 'ddbba.pago.cbu_cifrado', 'cbu_origen', 'COLUMN';
    EXEC sp_rename 'ddbba.unidad_funcional.cbu_cifrado', 'cbu', 'COLUMN';
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

--para ver las tablas bien
SELECT 
	nro_documento,
	tipo_documento
    nombre,
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', mail)) AS mail,
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', telefono)) AS telefono,
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', cbu)) AS cbu
FROM ddbba.persona;

SELECT 
	id_pago,
	id_consorcio,
	id_expensa,
	id_unidad_funcional,
	fecha_pago,
    monto,
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', cbu_origen)),
	estado
FROM ddbba.pago;


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
    CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('Grupo_1', cbu)),
	prorrateo
FROM ddbba.unidad_funcional;
