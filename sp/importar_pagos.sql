
CREATE OR ALTER PROCEDURE ddbba.sp_importar_pagos
    @ruta_archivo NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Importando archivo de pagos'
    -- ==========================================================
    -- 1. Se crea la tabla temporal
    -- ==========================================================
    CREATE TABLE #temp_pagos(
        id_pago INT UNIQUE, 
        fecha DATE,
        cbu VARCHAR(22), 
        valor VARCHAR(50)
    );

    SET DATEFORMAT dmy;

    -- ==========================================================
    -- 2. Se importa el archivo en la tabla temporal
    -- ==========================================================
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        BULK INSERT #temp_pagos
        FROM ''' + @ruta_archivo + N'''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''\n''
        );';

    EXEC sp_executesql @sql;

    -- ==========================================================
    -- 3. Se eliminan los registros vacíos
    -- ==========================================================
    DELETE FROM #temp_pagos
    WHERE fecha IS NULL OR valor IS NULL OR id_pago IS NULL;
    PRINT 'Inserción de pagos en la tabla final'
    -- ==========================================================
    -- 4. Se insertan los datos del archivo en la tabla de pagos evitando duplicados
    -- ==========================================================
    INSERT INTO ddbba.pago(id_pago, fecha_pago, monto, cbu_origen, estado) 
    SELECT 
        id_pago,
        fecha,
        CAST(ddbba.fn_limpiar_espacios(REPLACE(valor, '$', '')) AS DECIMAL(10,2)) AS monto,
        cbu,
        'no asociado' AS estado
    FROM #temp_pagos
    WHERE NOT EXISTS (
        SELECT 1
        FROM ddbba.pago p
        WHERE p.id_pago = #temp_pagos.id_pago
    );

    PRINT 'Finaliza la importación del archivo de pagos'

    DROP TABLE #temp_pagos;
END;
GO

exec ddbba.sp_importar_pagos @ruta_archivo = '/app/datasets/tp/pagos_consorcios.csv'