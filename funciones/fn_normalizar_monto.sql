CREATE OR ALTER FUNCTION ddbba.fn_normalizar_monto (@valor VARCHAR(50))
RETURNS DECIMAL (12,2)
AS
BEGIN

/* En esta funcion recibimos un valor monetario y lo convertimos en decimal(12,2), siguiendo estas reglas:
1) Limpiamos simbolos, espacios, y comas/puntos
2) Identificamos separador decimal (es coma o punto?)
3) Eliminamos el separador de miles y cambiamos decimal a punto
4) Devolvemos el numero normalizado
*/

DECLARE @resultado NVARCHAR(50), @entera NVARCHAR(50), @decimal NVARCHAR(10);

--1) Limpiamos caracteres no deseados
SET @resultado = ddbba.fn_limpiar_espacios (LTRIM(RTRIM(ISNULL(@valor, '')))); --borra espacios izq, der y entre medio
SET @resultado = REPLACE(@resultado, '$', ''); --saca $ (si lo tuviese)
SET @resultado = REPLACE(@resultado, ',', '');
SET @resultado = REPLACE(@resultado, '.', '');
--1) Agrega el punto decimal
SET @resultado = STUFF(@resultado,len(@resultado)-1,0,'.');
RETURN ISNULL(TRY_CAST(@resultado AS DECIMAL(12,2)), 0.00); --trata de castear el texto a decimal, si no puede, devuelve null y lo transformamos a 0.00
END
GO








