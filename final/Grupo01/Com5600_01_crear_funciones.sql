/*ENUNCIADO:CREACION DE FUNCIONES NECESARIAS PARA EL PROYECTO
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
use "Com5600_Grupo01"
go

CREATE OR ALTER FUNCTION ddbba.fn_normalizar_monto (@valor VARCHAR(50))
RETURNS DECIMAL(12,2)
AS
BEGIN

/* En esta funcion recibimos un valor monetario y lo convertimos en decimal(12,2), siguiendo estas reglas:
1) Limpiamos simbolos y espacios (caracteres no deseados)
2) Detectamos si tiene separador decimal
3) Eliminamos todos los separadores
4) Si tenia separador, insertamos el punto decimal
5) Devolvemos el numero normalizado
*/

    DECLARE @resultado NVARCHAR(50);
    DECLARE @tieneSeparador BIT;

    -- 1) Limpiamos caracteres no deseados
    SET @resultado = ddbba.fn_limpiar_espacios(LTRIM(RTRIM(ISNULL(@valor, '')))); --Borra espacios izq, der y entre medio
    SET @resultado = REPLACE(@resultado, '$', ''); --Saca el $ (si lo tuviese)

    -- 2) Detectamos si tiene separador decimal
    SET @tieneSeparador = CASE 
                            WHEN CHARINDEX(',', @resultado) > 0 OR CHARINDEX('.', @resultado) > 0 --CHARINDEX nos busca la primer aparicion del caracter, si es > 0 -> quiere decir que hay por lo menos UNO de los separadores (ya sea coma o punto)
                            THEN 1 
                            ELSE 0 
                          END;

    -- 3) Eliminamos todos los separadores
    SET @resultado = REPLACE(@resultado, ',', '');
    SET @resultado = REPLACE(@resultado, '.', '');

    -- 4) Si tenia separador, insertamos el punto decimal
    IF @tieneSeparador = 1 AND LEN(@resultado) > 2 --En el caso de que tenga tres digitos o mas,
        SET @resultado = STUFF(@resultado, LEN(@resultado) - 1, 0, '.'); --apuntamos a la posicion justo antes de los ultimos dos digitos (asumimos dos digitos decimales)
    --Si el numero tiene uno o dos digitos, entonces no entra al if y cuando castee solo le agrega el .00

    -- 5) Devolvemos el número normalizado
    RETURN ISNULL(TRY_CAST(@resultado AS DECIMAL(12,2)), 0.00); --Trata de castear el texto a decimal, si no puede, devuelve null y lo transformamos a 0.00
END
GO


CREATE OR ALTER FUNCTION ddbba.fn_limpiar_espacios (@valor VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
--- Limpia los espacios de una cadena de caracteres
    DECLARE @resultado VARCHAR(MAX) = @valor;

    SET @resultado = REPLACE(@resultado, CHAR(32), '');
    SET @resultado = REPLACE(@resultado, CHAR(160), '');
    SET @resultado = REPLACE(@resultado, CHAR(9), '');
    SET @resultado = REPLACE(@resultado, CHAR(10), '');
    SET @resultado = REPLACE(@resultado, CHAR(13), '');

    RETURN @resultado;
END
GO
