-- ============================================================
-- GIMNASIO "IRON LINKS" - Base de datos Oracle
-- Fichero: plsql.sql
-- Descripción: Procedimientos almacenados, funciones,
--              cursores y bloques PL/SQL de ejemplo.
-- Ejecutar después de insertar.sql (y triggers.sql).
-- ============================================================


-- ============================================================
-- PROCEDIMIENTO 1: inscribir_socio_en_clase
-- Propósito de negocio: registrar la inscripción de un socio
-- en una clase, comprobando que tenga contrato activo, que la
-- clase exista y que haya plazas libres. Devuelve un mensaje
-- de resultado para que la interfaz de recepción lo muestre.
-- Parámetros:
--   p_id_socio  IN  - Identificador del socio
--   p_id_clase  IN  - Identificador de la clase
--   p_resultado OUT - Mensaje con el resultado de la operación
-- ============================================================
CREATE OR REPLACE PROCEDURE inscribir_socio_en_clase (
    p_id_socio  IN  inscripcion_clase.id_socio%TYPE,
    p_id_clase  IN  inscripcion_clase.id_clase%TYPE,
    p_resultado OUT VARCHAR2
)
AS
    v_contratos_activos  NUMBER;
    v_plazas_libres      clase.plazas_libres%TYPE;
    v_ya_inscrito        NUMBER;
    v_nombre_clase       clase.nombre%TYPE;
    v_nombre_socio       VARCHAR2(180);
BEGIN
    -- 1. Verificar que el socio existe y tiene contrato activo
    SELECT COUNT(*)
    INTO v_contratos_activos
    FROM contrato
    WHERE id_socio = p_id_socio
      AND estado   = 'ACTIVO'
      AND (fecha_fin IS NULL OR fecha_fin >= SYSDATE);

    IF v_contratos_activos = 0 THEN
        p_resultado := 'ERROR: El socio no tiene contrato activo en vigor.';
        RETURN;
    END IF;

    -- 2. Verificar que la clase existe, está activa y tiene plazas
    BEGIN
        SELECT plazas_libres, nombre
        INTO v_plazas_libres, v_nombre_clase
        FROM clase
        WHERE id_clase = p_id_clase
          AND activa   = 'S';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_resultado := 'ERROR: La clase no existe o no está activa.';
            RETURN;
    END;

    IF v_plazas_libres <= 0 THEN
        p_resultado := 'ERROR: La clase "' || v_nombre_clase || '" no tiene plazas disponibles.';
        RETURN;
    END IF;

    -- 3. Verificar que no esté ya inscrito (constraint UNIQUE lo cubriría,
    --    pero lo comprobamos antes para dar un mensaje claro)
    SELECT COUNT(*)
    INTO v_ya_inscrito
    FROM inscripcion_clase
    WHERE id_socio = p_id_socio
      AND id_clase  = p_id_clase;

    IF v_ya_inscrito > 0 THEN
        p_resultado := 'AVISO: El socio ya estaba inscrito en esa clase.';
        RETURN;
    END IF;

    -- 4. Obtener nombre del socio para el mensaje
    SELECT nombre || ' ' || apellidos
    INTO v_nombre_socio
    FROM socio
    WHERE id_socio = p_id_socio;

    -- 5. Realizar la inscripción
    --    El trigger trg_plazas_inscripcion decrementará plazas_libres
    INSERT INTO inscripcion_clase (id_inscripcion, id_socio, id_clase, fecha_insc, asistio)
    VALUES (seq_inscripcion.NEXTVAL, p_id_socio, p_id_clase, SYSDATE, 'P');

    COMMIT;

    p_resultado := 'OK: ' || v_nombre_socio || ' inscrito/a en "' || v_nombre_clase || '" correctamente.';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR inesperado: ' || SQLERRM;
END inscribir_socio_en_clase;
/


-- ============================================================
-- PROCEDIMIENTO 2: renovar_contrato
-- Propósito de negocio: al vencer un contrato, el personal de
-- recepción puede renovarlo con la misma tarifa u otra distinta.
-- El procedimiento cierra el contrato anterior, crea uno nuevo
-- con inicio inmediato, registra el pago y devuelve el nuevo id.
-- Parámetros:
--   p_id_socio      IN  - Socio que renueva
--   p_id_tarifa     IN  - Tarifa elegida para la renovación
--   p_metodo_pago   IN  - Forma de pago (DOMICILIACION, TARJETA…)
--   p_id_contrato_n OUT - Id del nuevo contrato creado
--   p_resultado     OUT - Mensaje con el resultado
-- ============================================================
CREATE OR REPLACE PROCEDURE renovar_contrato (
    p_id_socio      IN  contrato.id_socio%TYPE,
    p_id_tarifa     IN  contrato.id_tarifa%TYPE,
    p_metodo_pago   IN  pago_cuota.metodo_pago%TYPE,
    p_id_contrato_n OUT contrato.id_contrato%TYPE,
    p_resultado     OUT VARCHAR2
)
AS
    v_precio         tarifa.precio%TYPE;
    v_nombre_tarifa  tarifa.nombre%TYPE;
    v_estado_socio   socio.estado%TYPE;
    v_nuevo_id       contrato.id_contrato%TYPE;
BEGIN
    -- 1. Verificar estado del socio
    SELECT estado INTO v_estado_socio
    FROM socio WHERE id_socio = p_id_socio;

    IF v_estado_socio NOT IN ('ACTIVO', 'SUSPENDIDO') THEN
        p_resultado := 'ERROR: No se puede renovar un socio en estado ' || v_estado_socio;
        RETURN;
    END IF;

    -- 2. Obtener precio de la tarifa elegida
    SELECT precio, nombre INTO v_precio, v_nombre_tarifa
    FROM tarifa
    WHERE id_tarifa = p_id_tarifa AND activa = 'S';

    -- 3. Cerrar contratos anteriores activos del socio
    UPDATE contrato
    SET estado = 'VENCIDO'
    WHERE id_socio = p_id_socio
      AND estado   = 'ACTIVO';

    -- 4. Crear el nuevo contrato
    --    El trigger trg_calcular_fecha_fin calcula fecha_fin automáticamente
    v_nuevo_id := seq_contrato.NEXTVAL;

    INSERT INTO contrato (id_contrato, id_socio, id_tarifa, fecha_inicio, importe_pag, estado)
    VALUES (v_nuevo_id, p_id_socio, p_id_tarifa, SYSDATE, v_precio, 'ACTIVO');

    -- 5. Registrar el pago
    INSERT INTO pago_cuota (id_pago, id_contrato, fecha_pago, importe, metodo_pago, observaciones)
    VALUES (seq_pago.NEXTVAL, v_nuevo_id, SYSDATE, v_precio, p_metodo_pago,
            'Renovación automática - ' || v_nombre_tarifa);

    -- 6. Si el socio estaba SUSPENDIDO, reactivarlo
    IF v_estado_socio = 'SUSPENDIDO' THEN
        UPDATE socio SET estado = 'ACTIVO' WHERE id_socio = p_id_socio;
    END IF;

    COMMIT;

    p_id_contrato_n := v_nuevo_id;
    p_resultado     := 'OK: Contrato ' || v_nuevo_id || ' creado para tarifa "' || v_nombre_tarifa || '".';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        p_resultado := 'ERROR: Tarifa no encontrada o no activa.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR inesperado: ' || SQLERRM;
END renovar_contrato;
/


-- ============================================================
-- FUNCIÓN 1: calcular_ingresos_mes
-- Propósito de negocio: devuelve el total recaudado en un mes
-- y año dados. Útil para informes mensuales de dirección.
-- Parámetros:
--   p_anio  IN - Año (ej: 2025)
--   p_mes   IN - Mes numérico (1-12)
-- Retorna: NUMBER con el total en euros
-- ============================================================
CREATE OR REPLACE FUNCTION calcular_ingresos_mes (
    p_anio IN NUMBER,
    p_mes  IN NUMBER
) RETURN NUMBER
AS
    v_total NUMBER := 0;
BEGIN
    SELECT NVL(SUM(importe), 0)
    INTO v_total
    FROM pago_cuota
    WHERE EXTRACT(YEAR  FROM fecha_pago) = p_anio
      AND EXTRACT(MONTH FROM fecha_pago) = p_mes;

    RETURN v_total;
END calcular_ingresos_mes;
/


-- ============================================================
-- FUNCIÓN 2: plazas_ocupadas_clase
-- Propósito de negocio: devuelve el número de plazas actualmente
-- ocupadas (inscritos confirmados o pendientes) en una clase.
-- Útil para comprobaciones en tiempo real desde la app del gimnasio.
-- Parámetros:
--   p_id_clase IN - Identificador de la clase
-- Retorna: NUMBER con el número de inscritos activos
-- ============================================================
CREATE OR REPLACE FUNCTION plazas_ocupadas_clase (
    p_id_clase IN clase.id_clase%TYPE
) RETURN NUMBER
AS
    v_ocupadas NUMBER;
    v_plazas_max clase.plazas_max%TYPE;
BEGIN
    -- Comprobación de que la clase existe
    SELECT plazas_max INTO v_plazas_max
    FROM clase WHERE id_clase = p_id_clase;

    SELECT COUNT(*)
    INTO v_ocupadas
    FROM inscripcion_clase
    WHERE id_clase = p_id_clase
      AND asistio  IN ('P', 'S');  -- Pendiente o Confirmado = plaza ocupada

    RETURN v_ocupadas;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1;  -- Clase no encontrada
END plazas_ocupadas_clase;
/


-- ============================================================
-- CURSOR EXPLÍCITO: enviar_alertas_renovacion
-- Propósito de negocio: recorre todos los contratos activos
-- que vencen en los próximos 15 días y registra en DBMS_OUTPUT
-- el aviso que debería enviarse a cada socio.
-- En un sistema real, esta lógica llamaría a un procedimiento de
-- envío de emails; aquí se simula con DBMS_OUTPUT.
-- ============================================================

-- Cursor que selecciona contratos próximos a vencer
DECLARE CURSOR cur_vencimientos IS
        SELECT
            s.id_socio,
            s.nombre || ' ' || s.apellidos  AS nombre_socio,
            s.email,
            t.nombre                         AS nombre_tarifa,
            c.fecha_fin,
            ROUND(c.fecha_fin - SYSDATE)     AS dias_restantes
        FROM
            contrato c
            JOIN socio  s ON s.id_socio  = c.id_socio
            JOIN tarifa t ON t.id_tarifa = c.id_tarifa
        WHERE
            c.estado    = 'ACTIVO'
            AND c.fecha_fin BETWEEN SYSDATE AND SYSDATE + 15
        ORDER BY
            c.fecha_fin ASC;

    v_fila       cur_vencimientos%ROWTYPE;
    v_contador   NUMBER := 0;
    v_urgente    BOOLEAN;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== ALERTAS DE RENOVACIÓN (' || TO_CHAR(SYSDATE,'DD/MM/YYYY') || ') ===');
    DBMS_OUTPUT.PUT_LINE('');

    OPEN cur_vencimientos;

    LOOP
        FETCH cur_vencimientos INTO v_fila;
        EXIT WHEN cur_vencimientos%NOTFOUND;

        v_contador := v_contador + 1;

        -- Lógica condicional: urgencia según días restantes
        IF v_fila.dias_restantes <= 3 THEN
            v_urgente := TRUE;
        ELSE
            v_urgente := FALSE;
        END IF;

        -- Construcción del mensaje (IF / CASE)
        DBMS_OUTPUT.PUT_LINE(
            CASE WHEN v_urgente THEN '[!!! URGENTE] ' ELSE '[Aviso] ' END
            || v_fila.nombre_socio
            || ' — Tarifa: ' || v_fila.nombre_tarifa
            || ' — Vence: ' || TO_CHAR(v_fila.fecha_fin, 'DD/MM/YYYY')
            || ' (' || v_fila.dias_restantes || ' días)'
            || ' — Email: ' || NVL(v_fila.email, 'sin email')
        );
    END LOOP;

    CLOSE cur_vencimientos;

    -- Resumen con FOR numérico
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Total de avisos generados: ' || v_contador);

    -- Demostración de WHILE: mostrar los próximos 3 meses con ingresos
    DECLARE
        v_mes   NUMBER := EXTRACT(MONTH FROM SYSDATE);
        v_anio  NUMBER := EXTRACT(YEAR  FROM SYSDATE);
        v_iter  NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('--- Ingresos de los últimos 3 meses ---');
        WHILE v_iter < 3 LOOP
            DBMS_OUTPUT.PUT_LINE(
                'Mes ' || LPAD(v_mes, 2, '0') || '/' || v_anio
                || ': ' || calcular_ingresos_mes(v_anio, v_mes) || ' €'
            );
            -- Retroceder un mes
            v_mes := v_mes - 1;
            IF v_mes = 0 THEN
                v_mes  := 12;
                v_anio := v_anio - 1;
            END IF;
            v_iter := v_iter + 1;
        END LOOP;
    END;

END;
/


-- ============================================================
-- BLOQUE ANÓNIMO DE PRUEBA: invocar procedimientos y funciones
-- ============================================================
DECLARE
    v_result  VARCHAR2(300);
    v_new_id  NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba inscribir_socio_en_clase ---');
    -- Intentar inscribir socio 4 en clase 2 (Spinning Tarde)
    inscribir_socio_en_clase(4, 2, v_result);
    DBMS_OUTPUT.PUT_LINE(v_result);

    -- Intentar inscribir socio sin contrato activo (socio 5 está en BAJA)
    inscribir_socio_en_clase(5, 3, v_result);
    DBMS_OUTPUT.PUT_LINE(v_result);

    DBMS_OUTPUT.PUT_LINE('--- Prueba plazas_ocupadas_clase ---');
    DBMS_OUTPUT.PUT_LINE('Plazas ocupadas en clase 1: ' || plazas_ocupadas_clase(1));

    DBMS_OUTPUT.PUT_LINE('--- Prueba calcular_ingresos_mes ---');
    DBMS_OUTPUT.PUT_LINE(
        'Ingresos enero 2025: ' || calcular_ingresos_mes(2025, 1) || ' €'
    );
END;
/


set serveroutput on;
-- ============================================================
-- FIN DE plsql.sql
-- ============================================================
