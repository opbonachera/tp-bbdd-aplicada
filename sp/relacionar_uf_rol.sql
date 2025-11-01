
CREATE OR ALTER PROCEDURE ddbba.sp_relacionar_uf_rol
AS
BEGIN
    SET NOCOUNT ON;

    -- Esto es para el caso en el que la tabla rol no posea alguna unidad funcional y se deban hacer actualizaciones

    PRINT 'Asociando unidades funcionales con la tabla de roles';

    UPDATE r
    SET 
        r.id_unidad_funcional = uf.id_unidad_funcional -- Asigna ID de UF a ROL
    FROM 
        ddbba.rol AS r
    JOIN 
        ddbba.unidad_funcional AS uf ON r.id_unidad_funcional = uf.id_unidad_funcional
    -- Actualiza las unidades funcionales
    WHERE 
        r.id_unidad_funcional IS NULL;
    
END
GO

exec  ddbba.sp_relacionar_uf_rol