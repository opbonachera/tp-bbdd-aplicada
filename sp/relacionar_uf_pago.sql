CREATE OR ALTER PROCEDURE ddbba.sp_relacionar_pagos
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Iniciando la asociación de pagos...';

    -- 1. Actualiza la tabla 'pago'
    UPDATE p
    SET 
        p.id_unidad_funcional = uf.id_unidad_funcional, -- Asigna el ID de la UF
        p.estado = 'asociado'                           -- Cambia el estado
    FROM 
        ddbba.pago AS p
    -- Une 'pago' con 'unidad_funcional' donde los CBU coincidan
    JOIN 
        ddbba.unidad_funcional AS uf ON p.cbu_origen = uf.cbu
    -- Solo actualiza los pagos que aún no están asociados
    WHERE 
        p.id_unidad_funcional IS NULL;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' pagos fueron asociados.';
   
END
GO

exec  ddbba.sp_relacionar_pagos 