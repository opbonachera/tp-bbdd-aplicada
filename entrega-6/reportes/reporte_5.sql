
-- 3 (tres) propietarios con mayor morosidad (morosidad = deuda total que tiene un propietario (persona) por las unidades funcionales que posee).
CREATE OR ALTER PROCEDURE ddbba.sp_reporte_5
    @id_consorcio INT = NULL,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL,
    @limite INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@limite)
        p.nro_documento,
        p.tipo_documento,
        p.nombre,
        p.mail,
        p.telefono,
        SUM(ISNULL(depuf.ingresos_adeudados, 0)) AS total_deuda
    FROM ddbba.persona p
    INNER JOIN ddbba.rol r
        ON p.nro_documento = r.nro_documento
        AND p.tipo_documento = r.tipo_documento
        AND r.nombre_rol = 'Propietario'
    INNER JOIN ddbba.unidad_funcional uf
        ON r.id_unidad_funcional = uf.id_unidad_funcional
        AND r.id_consorcio = uf.id_consorcio
    INNER JOIN ddbba.expensa e
        ON  uf.id_consorcio = e.id_consorcio
    INNER JOIN ddbba.estado_financiero depuf
        ON depuf.id_expensa = e.id_expensa
    WHERE (@id_consorcio IS NULL OR uf.id_consorcio = @id_consorcio)
      AND (@fecha_desde IS NULL OR e.fecha_emision >= @fecha_desde)
      AND (@fecha_hasta IS NULL OR e.fecha_emision <= @fecha_hasta)
    GROUP BY
        p.nro_documento,
        p.tipo_documento,
        p.nombre,
        p.mail,
        p.telefono
    HAVING SUM(ISNULL(depuf.ingresos_adeudados, 0)) > 0
    ORDER BY total_deuda DESC;
END;
GO

-- Top 3 propietarios más morosos de todo el sistema
EXEC ddbba.sp_top_propietarios_morosos;