


CREATE OR ALTER PROCEDURE ddbba.GenerarProrrateo
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualiza todos los prorrateos de una sola vez
    UPDATE uf
    SET uf.prorrateo = ROUND((CAST(uf.metros_cuadrados AS FLOAT) / tot.total_m2) * 100, 2)
    FROM ddbba.unidad_funcional AS uf
    INNER JOIN (
        SELECT id_consorcio, SUM(metros_cuadrados) AS total_m2
        FROM ddbba.unidad_funcional
        GROUP BY id_consorcio
    ) AS tot
        ON uf.id_consorcio = tot.id_consorcio;

    PRINT ' Prorrateo actualizado correctamente para todos los consorcios existentes.';
END;

EXEC ddbba.GenerarProrrateo;

SELECT departamento, metros_cuadrados, prorrateo
FROM ddbba.unidad_funcional
