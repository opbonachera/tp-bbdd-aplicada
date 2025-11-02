CREATE OR ALTER PROCEDURE ddbba.sp_relacionar_pagos
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Iniciando la asociaci�n de pagos...';

    -- ==========================================================
    -- 1. Actualiza el id de la unidad funcional cuando el CBU del pago coincide con el CBU de la tabla de uf
    -- ==========================================================
    UPDATE p
    SET 
        p.id_unidad_funcional = uf.id_unidad_funcional, -- Asigna el ID de la UF
        p.estado = 'asociado'                           -- Cambia el estado
    FROM 
        ddbba.pago AS p
    
    JOIN 
        ddbba.unidad_funcional AS uf ON p.cbu_origen = uf.cbu
    -- Solo actualiza los pagos que a�n no est�n asociados
    WHERE 
        p.id_unidad_funcional IS NULL;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' pagos fueron asociados.';
   
END
GO

exec  ddbba.sp_relacionar_pagos 