CREATE OR ALTER FUNCTION ddbba.fn_normalizar_monto (@valor VARCHAR(50))
RETURNS DECIMAL (12,2)
AS
BEGIN

/* En esta funcion recibimos un valor monetario y lo convertimos en decimal(12,2), siguiendo estas reglas:
1) Limpiamos simbolos, espacios, y comas/puntos
2) Identificamos separador decimal (coma o punto?)
3) Eliminamos el separador de miles y cambiamos decimal a punto
4) Devolvemos el numero normalizado
*/

DECLARE @resultado NVARCHAR(50);

--1) Limpiamos caracteres no deseados
SET @resultado = ddbba.fn_limpiar_espacios (LTRIM(RTRIM(ISNULL(@valor, '')))); --borra espacios izq, der y entre medio
SET @resultado = REPLACE(@resultado, '$', ''); --saca $ (si lo tuviese)

--2) Identificamos cual es el separador decimal mediante los distintos casos
DECLARE @posComa INT = CHARINDEX (',', REVERSE(@resultado)); --buscamos la ultima coma y punto en el texto (invirtiendolo y devolviendo la posicion para encontrar el separador del final)
DECLARE @posPunto INT = CHARINDEX ('.', REVERSE(@resultado));

--3) Eliminamos el separador de miles y cambiamos decimal a punto 
IF @posComa = 0 AND @posPunto = 0
BEGIN
	--CASO 1: No hay separadores -> convierto a numero directamente
	SET @resultado = @resultado;
END
ELSE IF @posComa > 0 AND @posPunto = 0
BEGIN
	--CASO 2: 12.530,25 -> convierto a 12530.25
	SET @resultado = REPLACE(@resultado, '.', ''); --saco punto de miles
	SET @resultado = REPLACE(@resultado, ',', '.'); --cambio coma decimal por punto
END
ELSE IF @posPunto > 0
BEGIN
	--CASO 3: 12,530.25 -> 12530.25
	SET @resultado = REPLACE(@resultado, ',', ''); --elimino coma de miles
END

--4) Devolvemos el numero normalizado
	RETURN ISNULL(TRY_CAST(@resultado AS DECIMAL(12,2)), 0.00); --trata de castear el texto a decimal, si no puede, devuelve null y lo transformamos a 0.00
END
GO







