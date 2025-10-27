CREATE OR ALTER PROCEDURE sp_importar_pagos
AS
BEGIN
    --- Importación del archivo de pagos
    CREATE TABLE #temp_pagos(
        id_pago INT unique, 
        fecha DATE,
        cbu VARCHAR(22), 
        valor VARCHAR(50)
    );
    
    SET DATEFORMAT dmy;

    BULK INSERT #temp_pagos
    FROM '/app/datasets/pagos_consorcios.csv'
    WITH(
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n'
    );

    --- Elimino filas vacías
    DELETE FROM #temp_pagos
    WHERE fecha IS NULL OR valor IS NULL or id_pago IS NULL;

    --- Elimino duplicados
    DELETE FROM #temp_pagos
    WHERE EXISTS (
        SELECT 1
        FROM ddbba.pago p
        WHERE p.id_pago = #temp_pagos.id_pago
    );

   -- Inserto en la tabla de pagos
   INSERT INTO ddbba.pago(id_pago, fecha_pago, monto, cbu_origen, estado) 
    SELECT 
        id_pago,
        fecha,
        CAST(ddbba.fn_limpiar_espacios(REPLACE(valor, '$', '')) AS DECIMAL(10,2)) AS monto,
        cbu,
        'no asociado' AS estado
    FROM #temp_pagos;
    
    -- Elimino la tabla temporal
    drop table #temp_pagos
END
GO

EXEC sp_importar_pagos;