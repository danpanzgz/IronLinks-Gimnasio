-- ============================================================
-- GIMNASIO "IRON LINKS" - Base de datos Oracle
-- Fichero: consultas.sql
-- Descripción: Batería de 10 consultas SQL con JOIN, GROUP BY,
--              HAVING, subconsultas y funciones de agregación.
-- Ejecutar después de insertar.sql.
-- ============================================================
ALTER SESSION SET CURRENT_SCHEMA = IRONLINKS;


-- ============================================================
-- CONSULTA 1 - SELECT con JOIN múltiple
-- Uso de negocio: "Listado completo de clases activas con su
-- monitor, sala y plazas disponibles." 

--Útil para el panel de recepción cuando un socio pregunta qué clases hay libres.
-- ============================================================
SELECT
    c.nombre            AS clase,
    c.dia_semana,
    c.hora_inicio,
    c.duracion_min      AS duracion_min,
    s.nombre            AS sala,
    s.aforo_max,
    m.nombre || ' ' || m.apellidos  AS monitor,
    c.plazas_libres
FROM
    clase   c
    JOIN sala    s ON s.id_sala    = c.id_sala
    JOIN monitor m ON m.id_monitor = c.id_monitor
WHERE
    c.activa = 'S'
ORDER BY
    c.dia_semana, c.hora_inicio;


-- ============================================================
-- CONSULTA 2 - GROUP BY + COUNT + JOIN
-- Uso de negocio: "¿Cuántos socios activos tiene cada tarifa?"
-- 
-- Permite al gerente saber qué planes son más populares y
-- decidir si relanzar alguna tarifa poco contratada.
-- ============================================================
SELECT
    t.nombre            AS tarifa,
    t.precio,
    COUNT(c.id_contrato) AS num_contratos_activos
FROM
    tarifa   t
    LEFT JOIN contrato c ON c.id_tarifa = t.id_tarifa
                         AND c.estado   = 'ACTIVO'
GROUP BY
    t.id_tarifa, t.nombre, t.precio
ORDER BY
    num_contratos_activos DESC;


-- ============================================================
-- CONSULTA 3 - GROUP BY + HAVING + SUM
-- Uso de negocio: "Socios que han gastado más de 200 € en total."
-- 
-- Identifica a los clientes más rentables para campañas de
-- fidelización o descuentos por volumen.
-- ============================================================
SELECT
    s.nombre || ' ' || s.apellidos  AS socio,
    s.email,
    SUM(p.importe)                  AS total_gastado
FROM
    socio       s
    JOIN contrato   c ON c.id_socio    = s.id_socio
    JOIN pago_cuota p ON p.id_contrato = c.id_contrato
GROUP BY
    s.id_socio, s.nombre, s.apellidos, s.email
HAVING
    SUM(p.importe) > 200
ORDER BY
    total_gastado DESC;


-- ============================================================
-- CONSULTA 4 - JOIN + MAX/MIN/AVG
-- Uso de negocio: "Estadísticas de facturación por método de
-- pago." 

-- Ayuda a contabilidad a analizar cómo pagan los socios.
-- ============================================================
SELECT
    p.metodo_pago,
    COUNT(*)            AS num_pagos,
    MIN(p.importe)      AS pago_min,
    MAX(p.importe)      AS pago_max,
    ROUND(AVG(p.importe), 2) AS pago_medio,
    SUM(p.importe)      AS total_recaudado
FROM
    pago_cuota p
GROUP BY
    p.metodo_pago
ORDER BY
    total_recaudado DESC;


-- ============================================================
-- CONSULTA 5 - Subconsulta en WHERE
-- Uso de negocio: "Socios con contrato activo que NO están
-- inscritos en ninguna clase." Son candidatos a llamarles para
-- ofrecerles clases grupales (venta cruzada).
-- ============================================================
SELECT
    s.nombre || ' ' || s.apellidos AS socio,
    s.telefono,
    s.email
FROM
    socio s
WHERE
    s.estado = 'ACTIVO'
    AND EXISTS (
        SELECT 1
        FROM contrato c
        WHERE c.id_socio = s.id_socio
          AND c.estado   = 'ACTIVO'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM inscripcion_clase ic
        WHERE ic.id_socio = s.id_socio
    )
ORDER BY
    s.apellidos;


-- ============================================================
-- CONSULTA 6 - JOIN + GROUP BY + HAVING (aforo)
-- Uso de negocio: "Clases con menos del 30% de plazas libres."
-- Alerta al gerente de clases casi llenas para abrir nuevas
-- sesiones o ampliar el aforo de sala.
-- ============================================================
SELECT
    c.nombre            AS clase,
    c.dia_semana,
    c.hora_inicio,
    c.plazas_max,
    c.plazas_libres,
    ROUND((c.plazas_libres / c.plazas_max) * 100, 1) AS pct_libre,
    s.nombre            AS sala
FROM
    clase c
    JOIN sala s ON s.id_sala = c.id_sala
WHERE
    c.activa = 'S'
    AND (c.plazas_libres / c.plazas_max) < 0.30
ORDER BY
    pct_libre ASC;


SELECT nombre, plazas_max, plazas_libres,
       ROUND((plazas_libres / plazas_max) * 100, 1) AS pct_libre
FROM IRONLINKS.clase
WHERE activa = 'S';

-- ============================================================
-- CONSULTA 7 - Subconsulta con IN + JOIN
-- Uso de negocio: "Monitores que imparten más de una clase a
-- la semana." 

-- Sirve para controlar la carga de trabajo de los
-- monitores y detectar si alguno está sobrecargado.
-- ============================================================
SELECT
    m.nombre || ' ' || m.apellidos AS monitor,
    m.especialidad,
    COUNT(c.id_clase)               AS num_clases
FROM
    monitor m
    JOIN clase c ON c.id_monitor = m.id_monitor
               AND c.activa = 'S'
GROUP BY
    m.id_monitor, m.nombre, m.apellidos, m.especialidad
HAVING
    COUNT(c.id_clase) > 1
ORDER BY
    num_clases DESC;


-- ============================================================
-- CONSULTA 8 - Subconsulta correlacionada
--
-- Uso de negocio: "Socios cuyo último contrato es de tipo
-- Básico y llevan más de 1 año en el gimnasio." 
-- ============================================================
SELECT
    s.nombre || ' ' || s.apellidos  AS socio,
    s.email,
    t.nombre                         AS tarifa_actual,
    ROUND(SYSDATE - s.fecha_alta)    AS dias_como_socio
FROM
    socio    s
    JOIN contrato c ON c.id_contrato = (
        -- Subconsulta correlacionada: último contrato de este socio
        SELECT MAX(c2.id_contrato)
        FROM contrato c2
        WHERE c2.id_socio = s.id_socio
    )
    JOIN tarifa t ON t.id_tarifa = c.id_tarifa
WHERE
    t.nombre LIKE '%Básica%'
    AND s.estado = 'ACTIVO'
    AND SYSDATE - s.fecha_alta > 365
ORDER BY
    dias_como_socio DESC;


-- ============================================================
-- CONSULTA 9 - JOIN triple + agregación
--
-- Uso de negocio: "Ranking de clases por número de inscripciones
-- confirmadas (asistio='S')." 

--Permite al equipo conocer qué
-- actividades tienen más demanda real para planificar la oferta.
-- ============================================================
SELECT
    c.nombre            AS clase,
    c.dia_semana,
    m.nombre || ' ' || m.apellidos AS monitor,
    COUNT(ic.id_inscripcion)        AS total_inscritos,
    SUM(CASE WHEN ic.asistio = 'S' THEN 1 ELSE 0 END) AS asistencias_confirmadas,
    SUM(CASE WHEN ic.asistio = 'N' THEN 1 ELSE 0 END) AS ausencias
FROM
    clase             c
    JOIN monitor       m  ON m.id_monitor  = c.id_monitor
    LEFT JOIN inscripcion_clase ic ON ic.id_clase = c.id_clase
GROUP BY
    c.id_clase, c.nombre, c.dia_semana, m.nombre, m.apellidos
ORDER BY
    asistencias_confirmadas DESC;


select * from inscripcion_clase;

-- ============================================================
-- CONSULTA 10 - Subconsulta en FROM (vista en línea) + JOIN
-- Uso de negocio: "Socios con contrato a punto de vencer en los
-- próximos 30 días." Permite a recepción llamarles con antelación
-- para ofrecerles la renovación y evitar la baja involuntaria.
-- ============================================================
SELECT
    s.nombre || ' ' || s.apellidos   AS socio,
    s.telefono,
    s.email,
    t.nombre                          AS tarifa,
    proximos.fecha_fin                AS vence_el,
    ROUND(proximos.fecha_fin - SYSDATE) AS dias_restantes
FROM
    socio s
    JOIN (
        -- Vista en línea: último contrato activo por socio
        SELECT
            c.id_socio,
            c.id_tarifa,
            c.fecha_fin,
            RANK() OVER (PARTITION BY c.id_socio ORDER BY c.fecha_fin DESC) AS rn
        FROM contrato c
        WHERE c.estado = 'ACTIVO'
          AND c.fecha_fin IS NOT NULL
    ) proximos ON proximos.id_socio = s.id_socio AND proximos.rn = 1
    JOIN tarifa t ON t.id_tarifa = proximos.id_tarifa
WHERE
    proximos.fecha_fin BETWEEN SYSDATE AND SYSDATE + 30
ORDER BY
    proximos.fecha_fin ASC;


-- ============================================================
-- FIN DE consultas.sql
-- ============================================================