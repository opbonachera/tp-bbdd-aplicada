
CREATE OR ALTER PROCEDURE ddbba.sp_importar_pagos
    @ruta NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #temp_pagos(
        id_pago INT UNIQUE, 
        fecha DATE,
        cbu VARCHAR(22), 
        valor VARCHAR(50)
    );

    SET DATEFORMAT dmy;

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
        BULK INSERT #temp_pagos
        FROM ''' + @ruta + N'''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''\n''
        );';

    EXEC sp_executesql @sql;

    DELETE FROM #temp_pagos
    WHERE fecha IS NULL OR valor IS NULL OR id_pago IS NULL;

    DELETE FROM #temp_pagos
    WHERE EXISTS (
        SELECT 1
        FROM ddbba.pago p
        WHERE p.id_pago = #temp_pagos.id_pago
    );


    INSERT INTO ddbba.pago(id_pago, fecha_pago, monto, cbu_origen, estado) 
    SELECT 
        id_pago,
        fecha,
        CAST(ddbba.fn_limpiar_espacios(REPLACE(valor, '$', '')) AS DECIMAL(10,2)) AS monto,
        cbu,
        'no asociado' AS estado
    FROM #temp_pagos;

    DROP TABLE #temp_pagos;
END;
GO

exec ddbba.sp_importar_pagos @ruta = '/app/datasets/tp/pagos_consorcios.csv'

select * from ddbba.pago