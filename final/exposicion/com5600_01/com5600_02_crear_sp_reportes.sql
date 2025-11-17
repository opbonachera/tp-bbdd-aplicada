/*---------------------------------------------------------
 Materia:     Base de datos aplicada. 
 Grupo:       1
 Comision:    5600
 Fecha:       2025-01-01
 Descripcion: Creacion de los procedimientos generan los reportes 1 a 6.
 Integrantes: Arcón Wogelman, Nazareno — 44792096
              Arriola Santiago — 41743980 
              Bonachera Ornella — 46119546
              Benitez Jimena — 46097948
              Guardia Gabriel — 42364065
              Perez, Olivia Constanza — 46641730
----------------------------------------------------------*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  INICIO DEL SCRIPT <<<<<<<<<<<<<<<<<<<<<<<<<<*/

USE Com5600_Grupo01;
GO

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CREACION DE PROCEDIMIENTOS PARA GENERAR REPORTES  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
-------------------------------------------------------------------------------------------------
/* ---
    Reporte 1.
        Flujo de caja semanal:
            - Total recaudado por semana
            - Promedio en el periodo
            - Acumulado progresivo
--- */
CREATE OR ALTER PROCEDURE ddbba.sp_reporte_1
    @id_consorcio INT = NULL, 
    @anio_desde INT = NULL,   
    @anio_hasta INT = NULL
WITH EXECUTE AS owner
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @where NVARCHAR(MAX) = N' WHERE 1=1 ';

    -- Se contruyen filtros dinamicos concatenando a la cadena del where según si el parámetro fue pasado al sp o no.
    IF @id_consorcio IS NOT NULL
        SET @where += N' AND e.id_consorcio = @id_consorcio ';

    IF @anio_desde IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) >= @anio_desde ';

    IF @anio_hasta IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) <= @anio_hasta ';

    --- Se utiliza SQL dinámico para la utilización del where con la lógica de concatenación. 
    SET @sql = N'
        WITH Pagos AS (
            SELECT
                p.id_pago, p.monto, p.fecha_pago,
                YEAR(p.fecha_pago) AS anio, DATEPART(WEEK, p.fecha_pago) AS semana
            FROM ddbba.pago p
            LEFT JOIN ddbba.expensa e ON e.id_expensa = p.id_expensa
            ' + @where + N'
        ),
        TotalSemanal AS (
            SELECT anio, semana,
                SUM(monto) AS total_semanal
            FROM Pagos 
            GROUP BY anio, semana
        )
        SELECT 
            anio, semana, total_semanal,
            AVG(total_semanal) OVER () AS promedio_general,
            SUM(total_semanal) OVER (ORDER BY anio, semana) AS acumulado_progresivo
        FROM TotalSemanal
        ORDER BY anio, semana;
    ';

    EXEC sp_executesql 
        @sql,
        N'@id_consorcio INT, @anio_desde INT, @anio_hasta INT',
        @id_consorcio=@id_consorcio,
        @anio_desde=@anio_desde,
        @anio_hasta=@anio_hasta;
END;
GO

----------------------------------------------------------------------------------------------------------
/*
    Reporte 2
        Presente el total de recaudación por mes y departamento en formato de tabla cruzada. 
*/
CREATE OR ALTER PROCEDURE ddbba.sp_reporte_2
    @min  DECIMAL(12,2) = NULL, 
    @max  DECIMAL(12,2) = NULL,
    @anio INT = NULL
WITH EXECUTE AS owner
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cols NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @where NVARCHAR(MAX) = N' WHERE 1=1 ';
    DECLARE @having NVARCHAR(MAX) = N'';

    -- Se contruyen filtros dinamicos concatenando a la cadena del where según si el parámetro fue pasado al sp o no.
     IF @anio IS NOT NULL
        SET @where += N' AND YEAR(p.fecha_pago) = @anio ';
    IF @min IS NOT NULL AND @max IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) BETWEEN @min AND @max ';
    ELSE IF @min IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) >= @min ';
    ELSE IF @max IS NOT NULL
        SET @having = N' HAVING SUM(p.monto) <= @max ';

    -- Se limpian los datos de departamento y se obtienen las columnas del PIVOT
    SELECT 
        @cols = STRING_AGG(
                    QUOTENAME(REPLACE(LTRIM(RTRIM(departamento)), ' ', '_')),
                    ','
                 )
    FROM (
        SELECT DISTINCT departamento
        FROM ddbba.unidad_funcional
    ) AS d;

    -- Se construye el SQL dinamico con los filtros generados previamente
    SET @sql = N'
        WITH mes_uf_CTE AS (
            SELECT 
                FORMAT(p.fecha_pago, ''yyyy-MM'') AS mes, 
                REPLACE(LTRIM(RTRIM(uf.departamento)), '' '', ''_'') AS departamento,
                SUM(p.monto) AS total_monto
            FROM ddbba.pago p
            JOIN ddbba.unidad_funcional uf  
                ON uf.id_unidad_funcional = p.id_unidad_funcional
            ' + @where + N'
            GROUP BY FORMAT(p.fecha_pago, ''yyyy-MM''), 
                     REPLACE(LTRIM(RTRIM(uf.departamento)), '' '', ''_'')
            ' + @having + N'
        )
        SELECT mes, ' + @cols + N'
        FROM mes_uf_CTE
        PIVOT (
            SUM(total_monto)
            FOR departamento IN (' + @cols + N')
        ) AS tabla_cruzada
        ORDER BY mes
        FOR XML PATH(''Mes''), ROOT(''Recaudacion''), ELEMENTS XSINIL;
    ';

    EXEC sp_executesql 
        @sql,
        N'@min DECIMAL(12,2), @max DECIMAL(12,2), @anio INT',
        @min=@min, @max=@max, @anio=@anio;
END;
GO

--------------------------------------------------------------------------------------
 /*
    Reporte 3
        Presente un cuadro cruzado con la recaudación total desagregada según su procedencia
        (ordinario, extraordinario, etc.) según el periodo.
*/
--IMPORTANTE (ANTES DE EJECUTAR EL SP):
--Para ejecutar un llamado a una API desde SQL primero vamos a tener que habilitar ciertos permisos que por default vienen bloqueados
--'Ole Automation Procedures' permite a SQL Server utilizar el controlador OLE para interactuar con los objetos

EXEC sp_configure 'show advanced options', 1;	--Para poder editar los permisos avanzados
RECONFIGURE;
GO
EXEC sp_configure 'Ole Automation Procedures', 1;	--Habilitamos esta opcion avanzada de OLE
RECONFIGURE;
GO

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_3
    @FechaDesde DATE = NULL,
    @FechaHasta DATE = NULL,
    @IdConsorcio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Estamos usando una API que devuelve el valor del dolar oficial, blue y el euro en tipo de cambio comprador y vendedor
    --Referencia: https://api.bluelytics.com.ar/

    -- ================================================
    -- Obtener el valor del dolar oficial (value_buy)
    -- ================================================

    --Vamos a convertir el valor total recaudado y sus desgloses a USD oficial, tipo de cambio comprador
    --Para eso, primero armamos el URL del llamado

    DECLARE @url NVARCHAR(256) = 'https://api.bluelytics.com.ar/v2/latest';

    DECLARE @Object INT;
    DECLARE @json TABLE(DATA NVARCHAR(MAX));
    DECLARE @datos NVARCHAR(MAX); --La usaremos para la posterior interpretacion del json
    DECLARE @valor_dolar DECIMAL(10,2);
    DECLARE @fecha_dolar DATETIME2; --Usamos datetime2 porque datetime esta limitada en el rango de anios

    BEGIN TRY
        EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT; -- Creamos una instancia de OLE que nos permite hacer los llamados
        EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE'; -- Definimos algunas propiedades del objeto para hacer una llamada HTTP Get
        EXEC sp_OAMethod @Object, 'SEND';

        --Si el SP devuelve una tabla, lo podemos almacenar con INSERT

        INSERT INTO @json EXEC sp_OAGetProperty @Object, 'ResponseText'; --Obtenemos el valor de la propiedad 'ResponseText' del objeto OLE despues de realizar la consulta
        EXEC sp_OADestroy @Object;

        --Interpretamos el JSON

        SET @datos = (SELECT DATA FROM @json);

        -- Extraemos el valor del dolar y la ultima fecha de actualizacion

        SELECT 
            @valor_dolar = JSON_VALUE(@datos, '$.oficial.value_buy'),
            @fecha_dolar = JSON_VALUE(@datos, '$.last_update');
    END TRY
    BEGIN CATCH
        PRINT 'Error al obtener el valor del dolar. Se usara 1 como valor por defecto.'; --Por si falla
        SET @valor_dolar = 1;
        SET @fecha_dolar = GETDATE();
    END CATCH;

    -- ============================================
    -- Consulta principal de recaudacion
    -- ============================================

    WITH gastos_union AS (
        SELECT

        --Total de Gastos Ordinarios dentro del periodo

            FORMAT(e.fecha_emision, 'yyyy-MM') AS Periodo,
            'Ordinario' AS Tipo,
            gaor.importe AS Importe
        FROM ddbba.expensa e
        INNER JOIN ddbba.gastos_ordinarios gaor 
            ON e.id_expensa = gaor.id_expensa
        WHERE 
            (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)
            AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)

        UNION ALL

        SELECT

        --Total de Gastos Extraordinarios dentro del periodo

            FORMAT(e.fecha_emision, 'yyyy-MM') AS Periodo,
            'Extraordinario' AS Tipo,
            ge.importe_total AS Importe
        FROM ddbba.expensa e
        INNER JOIN ddbba.gasto_extraordinario ge 
            ON e.id_expensa = ge.id_expensa
        WHERE 
            (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)
            AND (@IdConsorcio IS NULL OR e.id_consorcio = @IdConsorcio)
    )

    --Consulta final con los valores desagregados a mostrar

    SELECT 
        Periodo,
        ISNULL([Ordinario], 0) AS Total_Ordinario,
        CAST(ROUND((ISNULL([Ordinario], 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Ordinario_USD, --Casteamos a DECIMAL y redondeamos a dos digitos
        ISNULL([Extraordinario], 0) AS Total_Extraordinario,
        CAST(ROUND((ISNULL(Extraordinario, 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Extraordinario_USD,
        ISNULL([Ordinario], 0) + ISNULL([Extraordinario], 0) AS Total_Recaudado,
        CAST(ROUND((ISNULL([Ordinario], 0) + ISNULL([Extraordinario], 0)) / @valor_dolar, 2) AS DECIMAL(10,2)) AS Total_Recaudado_USD
    FROM gastos_union
    PIVOT (
        SUM(Importe)
        FOR Tipo IN ([Ordinario], [Extraordinario])
    ) AS pvt
    ORDER BY Periodo;


    -- ============================================
    -- Extraer dolar oficial y fecha
    -- ============================================

    --Podemos mostrar el valor del dolar actual y la ultima fecha de actualizacion en una consulta separada
    --para que quien ejecute el reporte este al tanto de que valor se utilizo al momento de ejecutarse el SP

    SELECT 
        CAST(JSON_VALUE(@datos, '$.oficial.value_buy') AS DECIMAL(10,2)) AS Dolar_Oficial_Compra,
        CONVERT(VARCHAR(19), TRY_CAST(JSON_VALUE(@datos, '$.last_update') AS DATETIME2), 120) AS Fecha_Actualizacion

END;

GO

-------------------------------------------------------------------------------------------------
/*
    Reporte 4. 
        Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos. 
*/
CREATE OR ALTER PROCEDURE ddbba.sp_reporte_4
    @id_consorcio INT = NULL,  -- filtrar por consorcio
    @AnioDesde INT = NULL,     -- año desde
    @AnioHasta INT = NULL      --  año hasta
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FechaDesde DATE = NULL;
    DECLARE @FechaHasta DATE = NULL;

    -- Rango de fechas
    IF @AnioDesde IS NOT NULL
        SET @FechaDesde = DATEFROMPARTS(@AnioDesde, 1, 1);
    IF @AnioHasta IS NOT NULL
        SET @FechaHasta = DATEFROMPARTS(@AnioHasta, 12, 31);


    -- TOP 5 MESES CON MAYORES GASTOS (Ordinarios + Extraordinarios)
    ;WITH GastosUnificados AS (
        SELECT 
            YEAR(e.fecha_emision) AS Anio,
            MONTH(e.fecha_emision) AS Mes,
            gor.importe AS Monto,
            'Ordinario' AS TipoGasto,
            e.id_consorcio
        FROM ddbba.gastos_ordinarios gor
        INNER JOIN ddbba.expensa e ON gor.id_expensa = e.id_expensa
        WHERE 
            (@id_consorcio IS NULL OR e.id_consorcio = @id_consorcio)
            AND (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)

        UNION ALL

        SELECT 
            YEAR(e.fecha_emision) AS Anio,
            MONTH(e.fecha_emision) AS Mes,
            ge.importe_total AS Monto,
            'Extraordinario' AS TipoGasto,
            e.id_consorcio
        FROM ddbba.gasto_extraordinario ge
        INNER JOIN ddbba.expensa e ON ge.id_expensa = e.id_expensa
        WHERE 
            (@id_consorcio IS NULL OR e.id_consorcio = @id_consorcio)
            AND (@FechaDesde IS NULL OR e.fecha_emision >= @FechaDesde)
            AND (@FechaHasta IS NULL OR e.fecha_emision <= @FechaHasta)
    ),
    GastosMensuales AS (
        SELECT 
            Anio,
            Mes,
            DATENAME(MONTH, DATEFROMPARTS(Anio, Mes, 1)) AS NombreMes,
            SUM(Monto) AS TotalGastos,
            SUM(CASE WHEN TipoGasto = 'Ordinario' THEN Monto ELSE 0 END) AS GastosOrdinarios,
            SUM(CASE WHEN TipoGasto = 'Extraordinario' THEN Monto ELSE 0 END) AS GastosExtraordinarios,
            COUNT(*) AS CantidadGastos,
            COUNT(CASE WHEN TipoGasto = 'Ordinario' THEN 1 END) AS CantOrdinarios,
            COUNT(CASE WHEN TipoGasto = 'Extraordinario' THEN 1 END) AS CantExtraordinarios
        FROM GastosUnificados
        GROUP BY Anio, Mes
    )
    SELECT TOP 5
        Anio AS [@Anio],
        Mes AS [@Mes],
        NombreMes AS [@NombreMes],
        TotalGastos AS [@TotalGastos],
        GastosOrdinarios AS [@GastosOrdinarios],
        GastosExtraordinarios AS [@GastosExtraordinarios],
        CantidadGastos AS [@CantidadGastos],
        CantOrdinarios AS [@CantOrdinarios],
        CantExtraordinarios AS [@CantExtraordinarios],
        CAST(Anio AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(Mes AS VARCHAR(2)), 2) AS [@PeriodoOrdenado]
    FROM GastosMensuales
    ORDER BY TotalGastos DESC
    FOR XML PATH('Mes'), ROOT('Top5MesesGastos'), TYPE;


    --  TOP 5 MESES CON MAYORES INGRESOS
    ;WITH IngresosMensuales AS (
        SELECT 
            YEAR(p.fecha_pago) AS Anio,
            MONTH(p.fecha_pago) AS Mes,
            DATENAME(MONTH, p.fecha_pago) AS NombreMes,
            SUM(p.monto) AS TotalIngresos,
            COUNT(*) AS CantidadPagos,
            COUNT(DISTINCT p.id_unidad_funcional) AS UnidadesPagaron
        FROM ddbba.pago p
        WHERE 
            p.estado = 'Aprobado'
            AND (@id_consorcio IS NULL OR p.id_consorcio = @id_consorcio)
            AND (@FechaDesde IS NULL OR p.fecha_pago >= @FechaDesde)
            AND (@FechaHasta IS NULL OR p.fecha_pago <= @FechaHasta)
        GROUP BY 
            YEAR(p.fecha_pago),
            MONTH(p.fecha_pago),
            DATENAME(MONTH, p.fecha_pago)
    )
    ---genera el XML
    SELECT TOP 5
        Anio AS [@Anio],
        Mes AS [@Mes],
        NombreMes AS [@NombreMes],
        TotalIngresos AS [@TotalIngresos],
        CantidadPagos AS [@CantidadPagos],
        UnidadesPagaron AS [@UnidadesPagaron],
        CAST(Anio AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(Mes AS VARCHAR(2)), 2) AS [@PeriodoOrdenado]
    FROM IngresosMensuales
    ORDER BY TotalIngresos DESC
    FOR XML PATH('Mes'), ROOT('Top5MesesIngresos'), TYPE;

END;
GO


--------------------------------------------------------------------------------------------
/*
    Reporte 5:
        Obtenga los 3 (tres) propietarios con mayor morosidad. Presente información de contacto y
        DNI de los propietarios para que la administración los pueda contactar o remitir el trámite al
        estudio jurídico.
*/
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
        SUM(ISNULL(depuf.deuda, 0)) AS total_deuda
    FROM ddbba.persona p
    INNER JOIN ddbba.rol r
        ON p.nro_documento = r.nro_documento
        AND p.tipo_documento = r.tipo_documento
        AND r.nombre_rol = 'Propietario'
    INNER JOIN ddbba.unidad_funcional uf
        ON r.id_unidad_funcional = uf.id_unidad_funcional
        AND r.id_consorcio = uf.id_consorcio
    INNER JOIN ddbba.detalle_expensas_por_uf depuf
        ON uf.id_unidad_funcional = depuf.id_unidad_funcional
        AND uf.id_consorcio = depuf.id_consorcio
    INNER JOIN ddbba.expensa e
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
    HAVING SUM(ISNULL(depuf.deuda, 0)) > 0
    ORDER BY total_deuda DESC;
END;
GO

-------------------------------------------------------------------------------------------------
/*
    Reporte 6
        Muestre las fechas de pagos de expensas ordinarias de cada UF y la cantidad de días que
        pasan entre un pago y el siguiente, para el conjunto examinado.

*/

CREATE OR ALTER PROCEDURE ddbba.sp_reporte_6
    @id_unidad_funcional INT = NULL,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH PagosUnicos AS (
        SELECT DISTINCT
            p.id_unidad_funcional,
            p.id_expensa,
            CAST(p.fecha_pago AS DATE) AS fecha_pago
        FROM ddbba.pago p
        INNER JOIN ddbba.expensa e ON p.id_expensa = e.id_expensa
        INNER JOIN ddbba.gastos_ordinarios go ON e.id_expensa = go.id_expensa
        INNER JOIN ddbba.unidad_funcional uf ON p.id_unidad_funcional = uf.id_unidad_funcional
        WHERE
            (@id_unidad_funcional IS NULL OR p.id_unidad_funcional = @id_unidad_funcional)
            AND (@fecha_desde IS NULL OR p.fecha_pago >= @fecha_desde)
            AND (@fecha_hasta IS NULL OR p.fecha_pago <= @fecha_hasta)
    ),
    PagosConLag AS (
        SELECT
            *,
            LAG(fecha_pago) OVER (PARTITION BY id_unidad_funcional ORDER BY fecha_pago) AS Fecha_Pago_Anterior
        FROM PagosUnicos
    )
    SELECT
        id_unidad_funcional,
        id_expensa,
        fecha_pago,
        Fecha_Pago_Anterior,
        DATEDIFF(DAY, Fecha_Pago_Anterior, fecha_pago) AS Dias_Entre_Pagos
    FROM PagosConLag
    ORDER BY id_unidad_funcional, fecha_pago;
END
GO
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DE LA CREACION DE PROCEDIMIENTOS PARA GENERAR REPORTES  <<<<<<<<<<<<<<<<<<<<<<<<<<*/
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FIN DEL SCRIPT  <<<<<<<<<<<<<<<<<<<<<<<<<<*/