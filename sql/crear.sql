-- ============================================================
-- GIMNASIO "IRON LINKS" - Base de datos Oracle
-- Fichero: crear.sql
-- Descripción: Creación de tablas, secuencias y restricciones.
-- Ejecutar primero. Incluye DROPs para facilitar la re-ejecución.
-- ============================================================

-- ============================================================
-- 1. ELIMINACIÓN DE TABLAS (orden inverso por FK)
-- ============================================================
DROP TABLE auditoria_socios    CASCADE CONSTRAINTS PURGE;
DROP TABLE pago_cuota          CASCADE CONSTRAINTS PURGE;
DROP TABLE inscripcion_clase   CASCADE CONSTRAINTS PURGE;
DROP TABLE clase               CASCADE CONSTRAINTS PURGE;
DROP TABLE contrato            CASCADE CONSTRAINTS PURGE;
DROP TABLE socio               CASCADE CONSTRAINTS PURGE;
DROP TABLE tarifa              CASCADE CONSTRAINTS PURGE;
DROP TABLE monitor             CASCADE CONSTRAINTS PURGE;
DROP TABLE sala                CASCADE CONSTRAINTS PURGE;

-- ============================================================
-- 2. ELIMINACIÓN DE SECUENCIAS
-- ============================================================
DROP SEQUENCE seq_sala;
DROP SEQUENCE seq_monitor;
DROP SEQUENCE seq_tarifa;
DROP SEQUENCE seq_socio;
DROP SEQUENCE seq_contrato;
DROP SEQUENCE seq_clase;
DROP SEQUENCE seq_inscripcion;
DROP SEQUENCE seq_pago;
DROP SEQUENCE seq_auditoria;

-- ============================================================
-- 3. SECUENCIAS
-- ============================================================

-- Identificadores sintéticos para cada entidad principal.
-- Se usa NUMBER autoincremental en lugar de claves naturales
-- para desacoplar la identidad lógica de los datos del negocio.

CREATE SEQUENCE seq_sala        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_monitor     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_tarifa      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_socio       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_contrato    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_clase       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_inscripcion START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_pago        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_auditoria   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- ============================================================
-- 4. TABLA: SALA
-- Justificación: las clases se imparten en salas físicas con
-- aforo máximo. Separar la sala de la clase permite reutilizarla
-- en distintos horarios y controlar la capacidad con triggers.
-- ============================================================
CREATE TABLE sala (
    id_sala       NUMBER         CONSTRAINT pk_sala PRIMARY KEY,
    nombre        VARCHAR2(60)   CONSTRAINT nn_sala_nombre   NOT NULL,
    aforo_max     NUMBER(3)      CONSTRAINT nn_sala_aforo    NOT NULL,
    descripcion   VARCHAR2(200),
    CONSTRAINT ck_sala_aforo CHECK (aforo_max BETWEEN 1 AND 200)
);

-- ============================================================
-- 5. TABLA: MONITOR
-- Justificación: cada clase tiene un monitor responsable.
-- Se separa de CLASE para poder reutilizar monitores, llevar
-- su especialidad y calcular su carga de trabajo.
-- ============================================================
CREATE TABLE monitor (
    id_monitor    NUMBER         CONSTRAINT pk_monitor PRIMARY KEY,
    nombre        VARCHAR2(80)   CONSTRAINT nn_monitor_nombre NOT NULL,
    apellidos     VARCHAR2(100)  CONSTRAINT nn_monitor_apell  NOT NULL,
    especialidad  VARCHAR2(60),
    telefono      VARCHAR2(15)   CONSTRAINT uq_monitor_tlf    UNIQUE,
    email         VARCHAR2(100)  CONSTRAINT uq_monitor_email  UNIQUE,
    fecha_alta    DATE           DEFAULT SYSDATE              NOT NULL
);

-- ============================================================
-- 6. TABLA: TARIFA
-- Justificación: el gimnasio ofrece varios planes (mensual,
-- trimestral, anual). Separar la tarifa del contrato permite
-- modificar precios sin alterar contratos vigentes.
-- ============================================================
CREATE TABLE tarifa (
    id_tarifa     NUMBER         CONSTRAINT pk_tarifa PRIMARY KEY,
    nombre        VARCHAR2(60)   CONSTRAINT nn_tarifa_nombre NOT NULL,
    duracion_dias NUMBER(4)      CONSTRAINT nn_tarifa_dias   NOT NULL,
    precio        NUMBER(8,2)    CONSTRAINT nn_tarifa_precio NOT NULL,
    descripcion   VARCHAR2(200),
    activa        CHAR(1)        DEFAULT 'S'                 NOT NULL,
    CONSTRAINT ck_tarifa_precio  CHECK (precio > 0),
    CONSTRAINT ck_tarifa_dias    CHECK (duracion_dias > 0),
    CONSTRAINT ck_tarifa_activa  CHECK (activa IN ('S','N'))
);

-- ============================================================
-- 7. TABLA: SOCIO
-- Justificación: entidad central del negocio. El NIF se marca
-- como UNIQUE porque es un identificador natural real del socio,
-- pero la PK es sintética para mayor flexibilidad interna.
-- ============================================================
CREATE TABLE socio (
    id_socio      NUMBER         CONSTRAINT pk_socio PRIMARY KEY,
    nif           VARCHAR2(10)   CONSTRAINT nn_socio_nif    NOT NULL
                                 CONSTRAINT uq_socio_nif    UNIQUE,
    nombre        VARCHAR2(80)   CONSTRAINT nn_socio_nombre NOT NULL,
    apellidos     VARCHAR2(100)  CONSTRAINT nn_socio_apell  NOT NULL,
    fecha_nac     DATE           CONSTRAINT nn_socio_fnac   NOT NULL,
    telefono      VARCHAR2(15),
    email         VARCHAR2(100)  CONSTRAINT uq_socio_email  UNIQUE,
    fecha_alta    DATE           DEFAULT SYSDATE             NOT NULL,
    estado        VARCHAR2(10)   DEFAULT 'ACTIVO'            NOT NULL,
    CONSTRAINT ck_socio_estado   CHECK (estado IN ('ACTIVO','BAJA','SUSPENDIDO'))
);

-- ============================================================
-- 8. TABLA: CONTRATO
-- Justificación: relación entre SOCIO y TARIFA con fechas.
-- Un socio puede tener varios contratos a lo largo del tiempo
-- (renovaciones), por eso es una entidad propia y no un campo
-- en SOCIO. La fecha_fin se calcula automáticamente por trigger.
-- ============================================================
CREATE TABLE contrato (
    id_contrato   NUMBER         CONSTRAINT pk_contrato PRIMARY KEY,
    id_socio      NUMBER         CONSTRAINT nn_contrato_socio  NOT NULL
                                 CONSTRAINT fk_contrato_socio  REFERENCES socio(id_socio),
    id_tarifa     NUMBER         CONSTRAINT nn_contrato_tarifa NOT NULL
                                 CONSTRAINT fk_contrato_tarifa REFERENCES tarifa(id_tarifa),
    fecha_inicio  DATE           CONSTRAINT nn_contrato_fi     NOT NULL,
    fecha_fin     DATE,          -- calculada por trigger al insertar
    importe_pag   NUMBER(8,2),   -- precio real pagado (puede diferir de tarifa por descuentos)
    estado        VARCHAR2(10)   DEFAULT 'ACTIVO'              NOT NULL,
    CONSTRAINT ck_contrato_estado CHECK (estado IN ('ACTIVO','VENCIDO','CANCELADO')),
    CONSTRAINT ck_contrato_fechas CHECK (fecha_fin IS NULL OR fecha_fin > fecha_inicio)
);

-- ============================================================
-- 9. TABLA: CLASE
-- Justificación: cada sesión tiene sala, monitor, horario y
-- plazas disponibles. Las plazas_libres se actualizan mediante
-- trigger en lugar de calcularse siempre con COUNT(*), lo que
-- mejora el rendimiento en consultas de disponibilidad.
-- ============================================================
CREATE TABLE clase (
    id_clase       NUMBER         CONSTRAINT pk_clase PRIMARY KEY,
    nombre         VARCHAR2(80)   CONSTRAINT nn_clase_nombre   NOT NULL,
    id_sala        NUMBER         CONSTRAINT nn_clase_sala     NOT NULL
                                  CONSTRAINT fk_clase_sala     REFERENCES sala(id_sala),
    id_monitor     NUMBER         CONSTRAINT nn_clase_monitor  NOT NULL
                                  CONSTRAINT fk_clase_monitor  REFERENCES monitor(id_monitor),
    dia_semana     VARCHAR2(10)   CONSTRAINT nn_clase_dia      NOT NULL,
    hora_inicio    VARCHAR2(5)    CONSTRAINT nn_clase_hora     NOT NULL,
    duracion_min   NUMBER(3)      DEFAULT 60                   NOT NULL,
    plazas_max     NUMBER(3)      CONSTRAINT nn_clase_plazas   NOT NULL,
    plazas_libres  NUMBER(3)      CONSTRAINT nn_clase_libres   NOT NULL,
    activa         CHAR(1)        DEFAULT 'S'                  NOT NULL,
    CONSTRAINT ck_clase_dia       CHECK (dia_semana IN ('LUNES','MARTES','MIERCOLES','JUEVES','VIERNES','SABADO','DOMINGO')),
    CONSTRAINT ck_clase_plazas    CHECK (plazas_max > 0),
    CONSTRAINT ck_clase_libres    CHECK (plazas_libres >= 0),
    CONSTRAINT ck_clase_activa    CHECK (activa IN ('S','N')),
    CONSTRAINT ck_clase_duracion  CHECK (duracion_min BETWEEN 15 AND 240)
);

-- ============================================================
-- 10. TABLA: INSCRIPCION_CLASE  (relación N:M entre SOCIO y CLASE)
-- Justificación: un socio puede asistir a muchas clases y una
-- clase tiene muchos socios. La relación N:M necesita tabla propia
-- para almacenar la fecha de inscripción y el estado de asistencia.
-- ============================================================
CREATE TABLE inscripcion_clase (
    id_inscripcion  NUMBER       CONSTRAINT pk_inscripcion PRIMARY KEY,
    id_socio        NUMBER       CONSTRAINT nn_insc_socio   NOT NULL
                                 CONSTRAINT fk_insc_socio   REFERENCES socio(id_socio),
    id_clase        NUMBER       CONSTRAINT nn_insc_clase   NOT NULL
                                 CONSTRAINT fk_insc_clase   REFERENCES clase(id_clase),
    fecha_insc      DATE         DEFAULT SYSDATE            NOT NULL,
    asistio         CHAR(1)      DEFAULT 'P',  -- P=Pendiente, S=Sí, N=No
    CONSTRAINT uq_insc_socio_clase UNIQUE (id_socio, id_clase),
    CONSTRAINT ck_insc_asistio     CHECK (asistio IN ('P','S','N'))
);

-- ============================================================
-- 11. TABLA: PAGO_CUOTA
-- Justificación: registra cada pago realizado por un contrato.
-- Un contrato puede generar varios pagos (pago mensual de
-- una tarifa anual en cuotas). Permite trazabilidad financiera.
-- ============================================================
CREATE TABLE pago_cuota (
    id_pago       NUMBER         CONSTRAINT pk_pago PRIMARY KEY,
    id_contrato   NUMBER         CONSTRAINT nn_pago_contrato NOT NULL
                                 CONSTRAINT fk_pago_contrato REFERENCES contrato(id_contrato),
    fecha_pago    DATE           DEFAULT SYSDATE             NOT NULL,
    importe       NUMBER(8,2)    CONSTRAINT nn_pago_importe  NOT NULL,
    metodo_pago   VARCHAR2(20)   DEFAULT 'DOMICILIACION'     NOT NULL,
    observaciones VARCHAR2(200),
    CONSTRAINT ck_pago_importe   CHECK (importe > 0),
    CONSTRAINT ck_pago_metodo    CHECK (metodo_pago IN ('DOMICILIACION','TARJETA','EFECTIVO','TRANSFERENCIA'))
);

-- ============================================================
-- 12. TABLA: AUDITORIA_SOCIOS
-- Justificación: tabla de auditoría para registrar altas,
-- bajas y cambios de estado de socios. Requerida por el
-- trigger de auditoría (Fase 5). No se borran registros de aquí.
-- ============================================================
CREATE TABLE auditoria_socios (
    id_auditoria  NUMBER         CONSTRAINT pk_auditoria PRIMARY KEY,
    id_socio      NUMBER         CONSTRAINT nn_audit_socio NOT NULL,
    accion        VARCHAR2(10)   CONSTRAINT nn_audit_accion NOT NULL,  -- INSERT/UPDATE/DELETE
    campo         VARCHAR2(60),
    valor_antes   VARCHAR2(200),
    valor_despues VARCHAR2(200),
    usuario_bd    VARCHAR2(60)   DEFAULT USER,
    fecha_cambio  DATE           DEFAULT SYSDATE NOT NULL,
    CONSTRAINT ck_audit_accion   CHECK (accion IN ('INSERT','UPDATE','DELETE'))
);

-- ============================================================
-- FIN DE crear.sql
-- ============================================================
