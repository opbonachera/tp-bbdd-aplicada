USE consorcios;
GO

CREATE OR ALTER PROCEDURE ddbba.sp_relacionar_pagos
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '---- Iniciando la asociación de pagos... ----';

    -- 1️ Asociar pagos con su unidad funcional según el CBU
    UPDATE p
    SET 
        p.id_unidad_funcional = uf.id_unidad_funcional,
        p.estado = 'asociado',
        p.id_consorcio = uf.id_consorcio
    FROM ddbba.pago AS p
    JOIN ddbba.unidad_funcional AS uf 
        ON p.cbu_origen = uf.cbu
    JOIN ddbba.consorcio AS c on c.id_consorcio = uf.id_consorcio
    WHERE p.id_unidad_funcional IS NULL;

    PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' pagos asociados a unidad funcional.';

    ;WITH UltimaExpensaPorUF AS (
        SELECT 
            uf.id_unidad_funcional,
            e.id_expensa,
            ROW_NUMBER() OVER (
                PARTITION BY uf.id_unidad_funcional 
                ORDER BY e.fecha_emision DESC
            ) AS rn
        FROM ddbba.unidad_funcional uf
        JOIN ddbba.expensa e 
            ON uf.id_consorcio = e.id_consorcio
    )
    UPDATE p
    SET p.id_expensa = uep.id_expensa
    FROM ddbba.pago p
    JOIN UltimaExpensaPorUF uep 
        ON p.id_unidad_funcional = uep.id_unidad_funcional AND uep.rn = 1
    WHERE p.id_expensa IS NULL;

    PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' pagos asociados a expensas.';
    PRINT '---- Finaliza la asociación de pagos... ----';
END;
GO