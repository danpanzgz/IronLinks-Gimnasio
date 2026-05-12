-- ============================================================
-- GIMNASIO "IRON LINKS" - Base de datos Oracle
-- Fichero: insertar.sql
-- Descripción: Datos de ejemplo realistas (mínimo 5-10 filas
--              por tabla principal). Ejecutar después de crear.sql.
-- ============================================================

-- ============================================================
-- 1. SALAS
-- ============================================================
INSERT INTO sala VALUES (seq_sala.NEXTVAL, 'Sala Cardio',        40, 'Equipada con cintas, bicicletas y elípticas');
INSERT INTO sala VALUES (seq_sala.NEXTVAL, 'Sala Spinning',      25, 'Bicicletas estáticas con proyector y música');
INSERT INTO sala VALUES (seq_sala.NEXTVAL, 'Sala Musculación',   60, 'Pesas libres y máquinas de musculación');
INSERT INTO sala VALUES (seq_sala.NEXTVAL, 'Sala Polivalente 1', 30, 'Yoga, pilates, stretching y aeróbic');
INSERT INTO sala VALUES (seq_sala.NEXTVAL, 'Sala Polivalente 2', 20, 'Boxeo, kickboxing y artes marciales');
INSERT INTO sala VALUES (seq_sala.NEXTVAL, 'Piscina',            15, 'Piscina cubierta climatizada, 25 metros');

-- ============================================================
-- 2. MONITORES
-- ============================================================
INSERT INTO monitor VALUES (seq_monitor.NEXTVAL, 'Carlos',   'Herrero Blanco',   'Spinning y Cardio',     '676100001', 'c.herrero@ironlinks.es',  DATE '2020-03-15');
INSERT INTO monitor VALUES (seq_monitor.NEXTVAL, 'Laura',    'Muñoz Serrano',    'Yoga y Pilates',        '676100002', 'l.munoz@ironlinks.es',    DATE '2019-09-01');
INSERT INTO monitor VALUES (seq_monitor.NEXTVAL, 'Andrés',   'Pardo Vega',       'Musculación',           '676100003', 'a.pardo@ironlinks.es',    DATE '2021-01-10');
INSERT INTO monitor VALUES (seq_monitor.NEXTVAL, 'Sofía',    'Ramos Díez',       'Natación',              '676100004', 's.ramos@ironlinks.es',    DATE '2022-06-20');
INSERT INTO monitor VALUES (seq_monitor.NEXTVAL, 'Miguel',   'Torres Castillo',  'Kickboxing',            '676100005', 'm.torres@ironlinks.es',   DATE '2018-11-05');
INSERT INTO monitor VALUES (seq_monitor.NEXTVAL, 'Elena',    'Gil Fernández',    'Aeróbic y Zumba',       '676100006', 'e.gil@ironlinks.es',      DATE '2023-02-14');

-- ============================================================
-- 3. TARIFAS
-- ============================================================
INSERT INTO tarifa VALUES (seq_tarifa.NEXTVAL, 'Mensual Básica',      30,  29.90, 'Acceso ilimitado a sala. Sin clases grupales.',    'S');
INSERT INTO tarifa VALUES (seq_tarifa.NEXTVAL, 'Mensual Completa',    30,  44.90, 'Acceso ilimitado + clases grupales incluidas.',    'S');
INSERT INTO tarifa VALUES (seq_tarifa.NEXTVAL, 'Trimestral Básica',   90,  79.90, 'Equivale a 2.66 meses. Ahorro vs mensual.',        'S');
INSERT INTO tarifa VALUES (seq_tarifa.NEXTVAL, 'Trimestral Completa', 90, 119.90, 'Trimestral con clases grupales.',                  'S');
INSERT INTO tarifa VALUES (seq_tarifa.NEXTVAL, 'Anual Básica',       365, 299.90, 'Mejor precio por mes. Solo sala.',                 'S');
INSERT INTO tarifa VALUES (seq_tarifa.NEXTVAL, 'Anual Completa',     365, 449.90, 'Precio más competitivo + todas las clases.',       'S');
INSERT INTO tarifa VALUES (seq_tarifa.NEXTVAL, 'Pase Día',             1,   8.00, 'Acceso puntual sin necesidad de contrato.',        'S');
INSERT INTO tarifa VALUES (seq_tarifa.NEXTVAL, 'Mensual Jubilados',   30,  22.90, 'Descuento para mayores de 65 años.',               'S');

-- ============================================================
-- 4. SOCIOS (15 socios para que las consultas sean significativas)
-- ============================================================
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '12345678A', 'Javier',    'López Martínez',     DATE '1985-04-12', '611000001', 'javier.lopez@email.com',   DATE '2022-01-10', 'ACTIVO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '23456789B', 'María',     'García Sánchez',     DATE '1990-07-25', '611000002', 'maria.garcia@email.com',   DATE '2022-03-05', 'ACTIVO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '34567890C', 'Pablo',     'Romero Jiménez',     DATE '1978-11-30', '611000003', 'pablo.romero@email.com',   DATE '2021-09-15', 'ACTIVO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '45678901D', 'Lucía',     'Navarro Torres',     DATE '1995-02-18', '611000004', 'lucia.navarro@email.com',  DATE '2023-01-20', 'ACTIVO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '56789012E', 'David',     'Moreno Ruiz',        DATE '1988-08-03', '611000005', 'david.moreno@email.com',   DATE '2022-07-11', 'BAJA');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '67890123F', 'Ana',       'Fernández Gil',      DATE '1970-12-22', '611000006', 'ana.fernandez@email.com',  DATE '2020-05-30', 'ACTIVO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '78901234G', 'Sergio',    'Díaz Herrero',       DATE '2000-03-07', '611000007', 'sergio.diaz@email.com',    DATE '2023-06-01', 'ACTIVO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '89012345H', 'Cristina',  'Muñoz Blanco',       DATE '1993-09-14', '611000008', 'cristina.munoz@email.com', DATE '2022-11-08', 'ACTIVO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '90123456I', 'Roberto',   'Alonso Vega',        DATE '1982-06-19', '611000009', 'roberto.alonso@email.com', DATE '2021-04-25', 'SUSPENDIDO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '01234567J', 'Marta',     'Castillo Pardo',     DATE '1997-01-31', '611000010', 'marta.castillo@email.com', DATE '2023-09-03', 'ACTIVO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '11223344K', 'Tomás',     'Serrano Ramos',      DATE '1966-05-08', '611000011', 'tomas.serrano@email.com',  DATE '2019-12-12', 'ACTIVO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '22334455L', 'Beatriz',   'Ortega Molina',      DATE '1987-10-27', '611000012', 'beatriz.ortega@email.com', DATE '2022-08-19', 'ACTIVO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '33445566M', 'Óscar',     'Prieto Rubio',       DATE '1975-03-16', '611000013', 'oscar.prieto@email.com',   DATE '2020-02-28', 'ACTIVO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '44556677N', 'Carmen',    'Domínguez Peña',     DATE '1991-07-04', '611000014', 'carmen.dominguez@email.com', DATE '2023-03-15', 'ACTIVO');
INSERT INTO socio VALUES (seq_socio.NEXTVAL, '55667788O', 'Alejandro', 'Ibáñez Cortés',      DATE '2001-11-22', '611000015', 'alejandro.ibanez@email.com', DATE '2024-01-07', 'ACTIVO');

-- ============================================================
-- 5. CONTRATOS
-- Las fechas_fin se calcularán automáticamente por trigger (trg_calcular_fecha_fin).
-- Se inserta importe_pag igual al precio de tarifa (sin descuento).
-- ============================================================

-- Tarifa Anual Completa (id=6, 449.90€, 365 días)
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 1,  6, DATE '2024-01-10', NULL, 449.90, 'ACTIVO');
-- Tarifa Mensual Completa (id=2, 44.90€, 30 días)
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 2,  2, DATE '2025-03-01', NULL, 44.90,  'ACTIVO');
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 3,  4, DATE '2025-01-15', NULL, 119.90, 'ACTIVO');
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 4,  2, DATE '2025-04-20', NULL, 44.90,  'ACTIVO');
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 5,  1, DATE '2024-06-01', NULL, 29.90,  'VENCIDO');
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 6,  8, DATE '2025-02-10', NULL, 22.90,  'ACTIVO');   -- jubilada
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 7,  2, DATE '2025-06-01', NULL, 44.90,  'ACTIVO');
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 8,  6, DATE '2025-01-08', NULL, 449.90, 'ACTIVO');
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 9,  3, DATE '2024-03-25', NULL, 79.90,  'VENCIDO');
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 10, 2, DATE '2025-09-03', NULL, 44.90,  'ACTIVO');
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 11, 5, DATE '2024-12-12', NULL, 299.90, 'ACTIVO');
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 12, 4, DATE '2025-08-19', NULL, 119.90, 'ACTIVO');
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 13, 6, DATE '2024-02-28', NULL, 449.90, 'VENCIDO');
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 14, 2, DATE '2025-03-15', NULL, 44.90,  'ACTIVO');
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 15, 1, DATE '2025-01-07', NULL, 29.90,  'ACTIVO');
-- Renovación de socio 3
INSERT INTO contrato VALUES (seq_contrato.NEXTVAL, 3,  6, DATE '2025-04-15', NULL, 449.90, 'ACTIVO');

-- ============================================================
-- 6. CLASES (plazas_libres = plazas_max al crear; trigger descuenta)
-- ============================================================
INSERT INTO clase VALUES (seq_clase.NEXTVAL, 'Spinning Matinal',   2, 1, 'LUNES',     '07:30', 45,  20, 20, 'S');
INSERT INTO clase VALUES (seq_clase.NEXTVAL, 'Spinning Tarde',     2, 1, 'MIERCOLES', '18:00', 45,  20, 20, 'S');
INSERT INTO clase VALUES (seq_clase.NEXTVAL, 'Yoga Suave',         4, 2, 'MARTES',    '10:00', 60,  15, 15, 'S');
INSERT INTO clase VALUES (seq_clase.NEXTVAL, 'Yoga Intensivo',     4, 2, 'JUEVES',    '19:00', 75,  15, 15, 'S');
INSERT INTO clase VALUES (seq_clase.NEXTVAL, 'Pilates',            4, 2, 'VIERNES',   '09:00', 60,  12, 12, 'S');
INSERT INTO clase VALUES (seq_clase.NEXTVAL, 'Zumba',              4, 6, 'MIERCOLES', '20:00', 60,  25, 25, 'S');
INSERT INTO clase VALUES (seq_clase.NEXTVAL, 'Kickboxing Básico',  5, 5, 'LUNES',     '20:00', 60,  16, 16, 'S');
INSERT INTO clase VALUES (seq_clase.NEXTVAL, 'Kickboxing Avanzado',5, 5, 'VIERNES',   '20:00', 60,  12, 12, 'S');
INSERT INTO clase VALUES (seq_clase.NEXTVAL, 'Natación Adultos',   6, 4, 'MARTES',    '08:00', 45,  10, 10, 'S');
INSERT INTO clase VALUES (seq_clase.NEXTVAL, 'Aqua Aeróbic',       6, 4, 'JUEVES',    '11:00', 45,  10, 10, 'S');
INSERT INTO clase VALUES (seq_clase.NEXTVAL, 'Aeróbic Clásico',    4, 6, 'SABADO',    '10:00', 50,  25, 25, 'S');

-- ============================================================
-- 7. INSCRIPCIONES A CLASES
-- Los triggers trg_plazas_inscripcion / trg_plazas_baja
-- decrementan/incrementan plazas_libres automáticamente.
-- ============================================================
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 1,  1, DATE '2025-01-12', 'S');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 1,  3, DATE '2025-01-12', 'S');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 2,  3, DATE '2025-03-06', 'S');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 2,  6, DATE '2025-03-06', 'P');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 3,  1, DATE '2025-01-20', 'S');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 4,  5, DATE '2025-04-21', 'P');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 6,  9, DATE '2025-02-11', 'S');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 6,  3, DATE '2025-02-11', 'S');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 7,  7, DATE '2025-06-02', 'P');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 7,  1, DATE '2025-06-02', 'P');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 8,  4, DATE '2025-01-10', 'S');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 8,  6, DATE '2025-01-10', 'S');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 10, 5, DATE '2025-09-04', 'P');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 11, 11,DATE '2025-01-01', 'S');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 12, 6, DATE '2025-08-20', 'P');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 13, 2, DATE '2024-03-01', 'S');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 14, 6, DATE '2025-03-16', 'S');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 15, 1, DATE '2025-01-08', 'P');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 1,  7, DATE '2025-02-01', 'S');
INSERT INTO inscripcion_clase VALUES (seq_inscripcion.NEXTVAL, 3,  9, DATE '2025-02-01', 'S');

-- ============================================================
-- 8. PAGOS DE CUOTA
-- ============================================================
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL,  1,  DATE '2024-01-10', 449.90, 'TARJETA',       'Pago anual completo');
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL,  2,  DATE '2025-03-01',  44.90, 'DOMICILIACION', NULL);
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL,  3,  DATE '2025-01-15', 119.90, 'DOMICILIACION', NULL);
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL,  4,  DATE '2025-04-20',  44.90, 'TARJETA',       NULL);
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL,  5,  DATE '2024-06-01',  29.90, 'EFECTIVO',      'Pagó en recepción');
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL,  6,  DATE '2025-02-10',  22.90, 'DOMICILIACION', NULL);
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL,  7,  DATE '2025-06-01',  44.90, 'TARJETA',       NULL);
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL,  8,  DATE '2025-01-08', 449.90, 'TRANSFERENCIA', 'Transferencia bancaria');
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL,  9,  DATE '2024-03-25',  79.90, 'DOMICILIACION', NULL);
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL, 10,  DATE '2025-09-03',  44.90, 'TARJETA',       NULL);
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL, 11,  DATE '2024-12-12', 299.90, 'DOMICILIACION', NULL);
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL, 12,  DATE '2025-08-19', 119.90, 'DOMICILIACION', NULL);
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL, 13,  DATE '2024-02-28', 449.90, 'TARJETA',       NULL);
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL, 14,  DATE '2025-03-15',  44.90, 'TARJETA',       NULL);
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL, 15,  DATE '2025-01-07',  29.90, 'EFECTIVO',      NULL);
-- Pago de renovación
INSERT INTO pago_cuota VALUES (seq_pago.NEXTVAL, 16,  DATE '2025-04-15', 449.90, 'DOMICILIACION', 'Renovación anual');

COMMIT;

-- ============================================================
-- FIN DE insertar.sql
-- ============================================================
