-- ============================================================
-- GIMNASIO "IRON LINKS" - Base de datos Oracle
-- Fichero: triggers.sql
-- Descripción: 6 triggers con justificación de negocio.
-- Ejecutar después de crear.sql y antes de insertar.sql.
-- ============================================================


-- ============================================================
-- TRIGGER 1: trg_calcular_fecha_fin
-- Evento: BEFORE INSERT ON contrato
-- Justificación de negocio:
--   La fecha de fin de un contrato se calcula sumando la duración
--   (en días) de la tarifa elegida a la fecha de inicio. Si el
--   personal introduce la fecha_inicio pero olvida fecha_fin, o
--   introduce un valor incorrecto, este trigger garantiza que
--   fecha_fin sea siempre coherente con la tarifa contratada.
--   Evita errores humanos en la gestión de contratos y asegura
--   la consistencia de los datos de vigencia.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_calcular_fecha_fin
BEFORE INSERT ON contrato
FOR EACH ROW
DECLARE
    v_dias tarifa.duracion_dias%TYPE;
BEGIN
    -- Obtener duración de la tarifa seleccionada
    SELECT duracion_dias
    INTO v_dias
    FROM tarifa
    WHERE id_tarifa = :NEW.id_tarifa;

    -- Calcular fecha_fin independientemente de lo que venga en el INSERT
    :NEW.fecha_fin := :NEW.fecha_inicio + v_dias;
END trg_calcular_fecha_fin;
/


-- ============================================================
-- TRIGGER 2: trg_plazas_inscripcion
-- Evento: AFTER INSERT ON inscripcion_clase
-- Justificación de negocio:
--   Cuando un socio se inscribe en una clase, las plazas libres
--   deben decrementarse automáticamente. Si esta lógica dependiera
--   de cada llamada de aplicación, podría saltearse accidentalmente.
--   El trigger garantiza la integridad del aforo a nivel de base de
--   datos. Además lanza un error si no quedan plazas, bloqueando la
--   inscripción antes de que se produzca inconsistencia.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_plazas_inscripcion
AFTER INSERT ON inscripcion_clase
FOR EACH ROW
DECLARE
    v_libres clase.plazas_libres%TYPE;
BEGIN
    -- Leer plazas actuales para verificar
    SELECT plazas_libres INTO v_libres
    FROM clase WHERE id_clase = :NEW.id_clase;

    IF v_libres <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            'No quedan plazas disponibles en esta clase.');
    END IF;

    -- Decrementar plazas libres
    UPDATE clase
    SET plazas_libres = plazas_libres - 1
    WHERE id_clase = :NEW.id_clase;
END trg_plazas_inscripcion;
/


-- ============================================================
-- TRIGGER 3: trg_plazas_baja
-- Evento: AFTER DELETE ON inscripcion_clase
-- Justificación de negocio:
--   Complemento del trigger anterior. Si un socio cancela su
--   inscripción a una clase, la plaza debe quedar libre de nuevo
--   para que otro socio pueda ocuparla. Sin este trigger habría
--   plazas "fantasma" bloqueadas por inscripciones eliminadas.
--   Garantiza que el aforo en tabla CLASE sea siempre la fuente
--   fiable de verdad para la disponibilidad en tiempo real.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_plazas_baja
AFTER DELETE ON inscripcion_clase
FOR EACH ROW
BEGIN
    UPDATE clase
    SET plazas_libres = plazas_libres + 1
    WHERE id_clase = :OLD.id_clase
      AND plazas_libres < plazas_max;  -- Nunca superar el máximo (integridad)
END trg_plazas_baja;
/


-- ============================================================
-- TRIGGER 4: trg_auditoria_socios
-- Evento: AFTER INSERT OR UPDATE OR DELETE ON socio
-- Justificación de negocio:
--   El RGPD y la política interna del gimnasio exigen tener un
--   registro de quién y cuándo modificó los datos personales de
--   un socio. Este trigger registra automáticamente en la tabla
--   AUDITORIA_SOCIOS cada alta, modificación de estado y baja.
--   No depende de la aplicación cliente, por lo que protege frente
--   a cambios directos en base de datos. Permite, por ejemplo,
--   demostrar la fecha exacta en la que se procesó la baja de un
--   socio en caso de reclamación.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_auditoria_socios
AFTER INSERT OR UPDATE OR DELETE ON socio
FOR EACH ROW
DECLARE
    v_accion VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_accion := 'INSERT';
        INSERT INTO auditoria_socios
            (id_auditoria, id_socio, accion, campo, valor_antes, valor_despues, usuario_bd, fecha_cambio)
        VALUES
            (seq_auditoria.NEXTVAL, :NEW.id_socio, v_accion,
             'estado', NULL, :NEW.estado, USER, SYSDATE);

    ELSIF DELETING THEN
        v_accion := 'DELETE';
        INSERT INTO auditoria_socios
            (id_auditoria, id_socio, accion, campo, valor_antes, valor_despues, usuario_bd, fecha_cambio)
        VALUES
            (seq_auditoria.NEXTVAL, :OLD.id_socio, v_accion,
             'BAJA_COMPLETA', :OLD.estado, NULL, USER, SYSDATE);

    ELSIF UPDATING('estado') THEN
        -- Solo auditamos cambios de estado (campo sensible de negocio)
        IF :OLD.estado != :NEW.estado THEN
            INSERT INTO auditoria_socios
                (id_auditoria, id_socio, accion, campo, valor_antes, valor_despues, usuario_bd, fecha_cambio)
            VALUES
                (seq_auditoria.NEXTVAL, :NEW.id_socio, 'UPDATE',
                 'estado', :OLD.estado, :NEW.estado, USER, SYSDATE);
        END IF;

    ELSIF UPDATING('email') THEN
        INSERT INTO auditoria_socios
            (id_auditoria, id_socio, accion, campo, valor_antes, valor_despues, usuario_bd, fecha_cambio)
        VALUES
            (seq_auditoria.NEXTVAL, :NEW.id_socio, 'UPDATE',
             'email', :OLD.email, :NEW.email, USER, SYSDATE);
    END IF;
END trg_auditoria_socios;
/


-- ============================================================
-- TRIGGER 5: trg_validar_edad_socio
-- Evento: BEFORE INSERT OR UPDATE ON socio
-- Justificación de negocio:
--   El gimnasio no puede admitir socios menores de 16 años sin
--   autorización parental (se gestiona aparte). La restricción
--   CHECK no puede comparar fecha_nac con SYSDATE porque SYSDATE
--   cambia con el tiempo. Este trigger calcula la edad real en el
--   momento del registro y lanza un error si el socio es menor de
--   16 años, cumpliendo así la política de admisión del gimnasio.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_validar_edad_socio
BEFORE INSERT OR UPDATE ON socio
FOR EACH ROW
DECLARE
    v_edad NUMBER;
BEGIN
    -- Calcular edad en años completos
    v_edad := FLOOR(MONTHS_BETWEEN(SYSDATE, :NEW.fecha_nac) / 12);

    IF v_edad < 16 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'El socio debe tener al menos 16 años. Edad calculada: ' || v_edad || ' años.');
    END IF;
END trg_validar_edad_socio;
/


-- ============================================================
-- TRIGGER 6: trg_no_solapamiento_clase
-- Evento: BEFORE INSERT OR UPDATE ON clase
-- Justificación de negocio:
--   Un monitor no puede impartir dos clases distintas el mismo
--   día a la misma hora en el mismo gimnasio (conflicto de agenda).
--   Igualmente, una sala no puede albergar dos clases simultáneas.
--   Estas reglas no pueden expresarse con CHECK porque implican
--   comparar la fila nueva contra otras filas de la misma tabla.
--   El trigger previene la programación errónea de horarios,
--   evitando conflictos que desembocarían en reclamaciones de
--   socios o en monitores que aparecen doblados en el horario.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_no_solapamiento_clase
BEFORE INSERT OR UPDATE ON clase
FOR EACH ROW
DECLARE
    v_conflicto_monitor NUMBER;
    v_conflicto_sala    NUMBER;
BEGIN
    -- Verificar que el monitor no tiene ya otra clase ese día y hora
    SELECT COUNT(*)
    INTO v_conflicto_monitor
    FROM clase
    WHERE id_monitor = :NEW.id_monitor
      AND dia_semana  = :NEW.dia_semana
      AND hora_inicio = :NEW.hora_inicio
      AND activa      = 'S'
      AND id_clase   != NVL(:NEW.id_clase, -1);  -- Excluir la propia fila en UPDATE

    IF v_conflicto_monitor > 0 THEN
        RAISE_APPLICATION_ERROR(-20003,
            'El monitor ya tiene una clase asignada ese día y hora.');
    END IF;

    -- Verificar que la sala no está ocupada a esa hora
    SELECT COUNT(*)
    INTO v_conflicto_sala
    FROM clase
    WHERE id_sala    = :NEW.id_sala
      AND dia_semana  = :NEW.dia_semana
      AND hora_inicio = :NEW.hora_inicio
      AND activa      = 'S'
      AND id_clase   != NVL(:NEW.id_clase, -1);

    IF v_conflicto_sala > 0 THEN
        RAISE_APPLICATION_ERROR(-20004,
            'La sala ya está ocupada a esa hora. Elige otra sala u hora.');
    END IF;
END trg_no_solapamiento_clase;
/


-- ============================================================
-- FIN DE triggers.sql
-- ============================================================
