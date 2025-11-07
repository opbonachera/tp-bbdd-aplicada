use "consorcios"
go
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
