-- =====================================================================
--  Base de datos de práctica: COLEGIO
--  Motor: MariaDB / MySQL
--  Uso:   mariadb -u jorge -p < colegio.sql
--
--  Contiene: grados, secciones, profesores, alumnos, cursos,
--            dictado (qué profesor enseña qué curso en qué sección)
--            y notas por bimestre (escala vigesimal 0-20, aprueba con 11).
--
--  Casos especiales a propósito (para practicar LEFT JOIN, NULL, etc.):
--    - Una sección SIN tutor (4to B).
--    - Una profesora que NO dicta ningún curso (Arte).
--    - Alumnos SIN teléfono de apoderado (NULL).
--    - Dos alumnos RETIRADOS sin sección (uno con notas del 1er bimestre).
-- =====================================================================

DROP DATABASE IF EXISTS colegio;
CREATE DATABASE colegio CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE colegio;

-- ---------------------------------------------------------------------
--  TABLAS
-- ---------------------------------------------------------------------

CREATE TABLE profesores (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    nombres        VARCHAR(60)  NOT NULL,
    apellidos      VARCHAR(60)  NOT NULL,
    dni            CHAR(8)      NOT NULL UNIQUE,
    especialidad   VARCHAR(50)  NOT NULL,
    email          VARCHAR(100) UNIQUE,
    telefono       VARCHAR(15),
    fecha_ingreso  DATE         NOT NULL,
    sueldo         DECIMAL(8,2) NOT NULL CHECK (sueldo > 0)
);

CREATE TABLE grados (
    id      INT AUTO_INCREMENT PRIMARY KEY,
    nombre  VARCHAR(30) NOT NULL UNIQUE,
    nivel   ENUM('Primaria', 'Secundaria') NOT NULL
);

CREATE TABLE secciones (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    grado_id  INT     NOT NULL,
    letra     CHAR(1) NOT NULL,
    aula      VARCHAR(10),
    tutor_id  INT NULL,
    UNIQUE (grado_id, letra),
    FOREIGN KEY (grado_id) REFERENCES grados(id),
    FOREIGN KEY (tutor_id) REFERENCES profesores(id) ON DELETE SET NULL
);

CREATE TABLE alumnos (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    nombres             VARCHAR(60) NOT NULL,
    apellidos           VARCHAR(60) NOT NULL,
    dni                 CHAR(8)     NOT NULL UNIQUE,
    fecha_nacimiento    DATE        NOT NULL,
    sexo                ENUM('M', 'F') NOT NULL,
    distrito            VARCHAR(40),
    telefono_apoderado  VARCHAR(15) NULL,
    seccion_id          INT NULL,
    estado              ENUM('Activo', 'Retirado') NOT NULL DEFAULT 'Activo',
    fecha_registro      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (seccion_id) REFERENCES secciones(id) ON DELETE SET NULL
);

CREATE TABLE cursos (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    nombre           VARCHAR(50) NOT NULL UNIQUE,
    horas_semanales  TINYINT     NOT NULL CHECK (horas_semanales BETWEEN 1 AND 10)
);

CREATE TABLE dictado (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    curso_id     INT NOT NULL,
    seccion_id   INT NOT NULL,
    profesor_id  INT NOT NULL,
    UNIQUE (curso_id, seccion_id),
    FOREIGN KEY (curso_id)    REFERENCES cursos(id),
    FOREIGN KEY (seccion_id)  REFERENCES secciones(id),
    FOREIGN KEY (profesor_id) REFERENCES profesores(id)
);

CREATE TABLE notas (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    alumno_id       INT          NOT NULL,
    curso_id        INT          NOT NULL,
    bimestre        TINYINT      NOT NULL CHECK (bimestre BETWEEN 1 AND 4),
    nota            DECIMAL(4,2) NOT NULL CHECK (nota BETWEEN 0 AND 20),
    fecha_registro  DATE         NOT NULL,
    UNIQUE (alumno_id, curso_id, bimestre),
    FOREIGN KEY (alumno_id) REFERENCES alumnos(id) ON DELETE CASCADE,
    FOREIGN KEY (curso_id)  REFERENCES cursos(id)
);

-- ---------------------------------------------------------------------
--  DATOS
-- ---------------------------------------------------------------------

INSERT INTO profesores (nombres, apellidos, dni, especialidad, email, telefono, fecha_ingreso, sueldo) VALUES
('Rosa María',   'Quispe Huamán',    '40123456', 'Matemática',           'rquispe@colegio.edu.pe',    '987654321', '2015-03-01', 3200.00),
('Carlos Alberto','Mendoza Ríos',    '41234567', 'Comunicación',         'cmendoza@colegio.edu.pe',   '986543210', '2018-03-01', 2900.00),
('Lucía',        'Fernández Torres', '42345678', 'Ciencia y Tecnología', 'lfernandez@colegio.edu.pe', NULL,        '2020-03-01', 2800.00),
('Jorge Luis',   'Paredes Salazar',  '43456789', 'Historia',             'jparedes@colegio.edu.pe',   '985432109', '2012-03-01', 3500.00),
('Ana Sofía',    'Castillo Vega',    '44567890', 'Inglés',               'acastillo@colegio.edu.pe',  '984321098', '2022-03-01', 2600.00),
('Miguel Ángel', 'Rojas Campos',     '45678901', 'Educación Física',     'mrojas@colegio.edu.pe',     '983210987', '2019-03-01', 2700.00),
('Patricia',     'Gutiérrez Lara',   '46789012', 'Arte',                 'pgutierrez@colegio.edu.pe', NULL,        '2024-03-01', 2400.00);

INSERT INTO grados (nombre, nivel) VALUES
('3ro de Secundaria', 'Secundaria'),
('4to de Secundaria', 'Secundaria'),
('5to de Secundaria', 'Secundaria');

-- 4to B (grado 2, letra B) no tiene tutor asignado.
INSERT INTO secciones (grado_id, letra, aula, tutor_id) VALUES
(1, 'A', '301', 1),
(1, 'B', '302', 2),
(2, 'A', '401', 3),
(2, 'B', '402', NULL),
(3, 'A', '501', 4),
(3, 'B', '502', 5);

INSERT INTO cursos (nombre, horas_semanales) VALUES
('Matemática',           6),
('Comunicación',         5),
('Ciencia y Tecnología', 4),
('Historia',             3),
('Inglés',               3),
('Educación Física',     2);

-- Cada profesor enseña el curso de su especialidad en todas las secciones.
-- (La profesora de Arte no tiene curso, así que no dicta nada.)
INSERT INTO dictado (curso_id, seccion_id, profesor_id)
SELECT c.id, s.id, p.id
FROM cursos c
JOIN profesores p ON p.especialidad = c.nombre
CROSS JOIN secciones s;

INSERT INTO alumnos (nombres, apellidos, dni, fecha_nacimiento, sexo, distrito, telefono_apoderado, seccion_id) VALUES
-- 3ro A
('Mateo',     'García López',     '71234501', '2011-05-14', 'M', 'San Isidro',   '987100001', 1),
('Valentina', 'Huamán Ccori',     '71234502', '2011-08-22', 'F', 'Lince',        '987100002', 1),
('Sebastián', 'Torres Vargas',    '71234503', '2012-01-30', 'M', 'Jesús María',  NULL,        1),
('Camila',    'Flores Medina',    '71234504', '2011-11-03', 'F', 'Miraflores',   '987100004', 1),
-- 3ro B
('Diego',     'Ramírez Soto',     '71234505', '2011-03-19', 'M', 'Surco',        '987100005', 2),
('Lucía',     'Chávez Ponce',     '71234506', '2011-07-07', 'F', 'San Borja',    '987100006', 2),
('Thiago',    'Vásquez Ruiz',     '71234507', '2011-12-25', 'M', 'Magdalena',    NULL,        2),
('Isabella',  'Morales Díaz',     '71234508', '2012-02-11', 'F', 'Pueblo Libre', '987100008', 2),
-- 4to A
('Joaquín',   'Castro Alarcón',   '71234509', '2010-04-02', 'M', 'San Isidro',   '987100009', 3),
('Ximena',    'Salas Ugarte',     '71234510', '2010-09-15', 'F', 'Lince',        '987100010', 3),
('Adrián',    'Cárdenas Ríos',    '71234511', '2010-06-28', 'M', 'Surco',        '987100011', 3),
('Mariana',   'Espinoza Rivera',  '71234512', '2011-01-09', 'F', 'Miraflores',   NULL,        3),
-- 4to B
('Gabriel',   'Navarro Quispe',   '71234513', '2010-10-21', 'M', 'Jesús María',  '987100013', 4),
('Daniela',   'Paz Herrera',      '71234514', '2010-03-05', 'F', 'San Borja',    '987100014', 4),
('Nicolás',   'Ibáñez Cruz',      '71234515', '2010-12-12', 'M', 'Magdalena',    '987100015', 4),
('Antonella', 'Reyes Palacios',   '71234516', '2010-07-30', 'F', 'Pueblo Libre', '987100016', 4),
-- 5to A
('Alejandro', 'Mendoza Lazo',     '71234517', '2009-05-27', 'M', 'San Isidro',   '987100017', 5),
('Fernanda',  'Aguilar Ccahuana', '71234518', '2009-08-16', 'F', 'Surco',        NULL,        5),
('Rodrigo',   'Silva Benavides',  '71234519', '2010-01-24', 'M', 'Lince',        '987100019', 5),
('Renata',    'Ortiz Delgado',    '71234520', '2009-11-08', 'F', 'Miraflores',   '987100020', 5),
-- 5to B
('Santiago',  'Huerta Mamani',    '71234521', '2009-04-13', 'M', 'San Borja',    '987100021', 6),
('Valeria',   'Campos Linares',   '71234522', '2009-06-01', 'F', 'Jesús María',  '987100022', 6),
('Emilio',    'Zevallos Prado',   '71234523', '2009-09-29', 'M', 'Magdalena',    '987100023', 6),
('Luana',     'Peña Gallardo',    '71234524', '2010-02-17', 'F', 'Pueblo Libre', NULL,        6);

-- Alumnos retirados (sin sección).
INSERT INTO alumnos (nombres, apellidos, dni, fecha_nacimiento, sexo, distrito, telefono_apoderado, seccion_id, estado) VALUES
('Bruno',   'Lozano Tapia', '71234525', '2010-08-08', 'M', 'Surco', '987100025', NULL, 'Retirado'),
('Alessia', 'Vera Montes',  '71234526', '2011-04-20', 'F', 'Lince', NULL,        NULL, 'Retirado');

-- Notas de los bimestres 1, 2 y 3 para todos los alumnos activos.
-- Se generan con una fórmula para no escribir cientos de filas a mano
-- (los valores quedan entre 07.00 y 19.50, así hay aprobados y desaprobados).
INSERT INTO notas (alumno_id, curso_id, bimestre, nota, fecha_registro)
SELECT a.id,
       c.id,
       b.n,
       7 + MOD(a.id * 7 + c.id * 11 + b.n * 5, 13) + MOD(a.id + c.id, 2) * 0.5,
       CASE b.n
           WHEN 1 THEN '2026-05-08'
           WHEN 2 THEN '2026-07-17'
           WHEN 3 THEN '2026-10-09'
       END
FROM alumnos a
CROSS JOIN cursos c
CROSS JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3) AS b
WHERE a.estado = 'Activo';

-- Bruno se retiró después del 1er bimestre: solo tiene esas notas.
INSERT INTO notas (alumno_id, curso_id, bimestre, nota, fecha_registro)
SELECT (SELECT id FROM alumnos WHERE dni = '71234525'), c.id, 1, 12.00, '2026-05-08'
FROM cursos c;

-- ---------------------------------------------------------------------
--  Verificación rápida (deberías ver: 7, 6, 26, 6, 36, 438)
-- ---------------------------------------------------------------------
SELECT 'profesores' AS tabla, COUNT(*) AS filas FROM profesores
UNION ALL SELECT 'secciones', COUNT(*) FROM secciones
UNION ALL SELECT 'alumnos',   COUNT(*) FROM alumnos
UNION ALL SELECT 'cursos',    COUNT(*) FROM cursos
UNION ALL SELECT 'dictado',   COUNT(*) FROM dictado
UNION ALL SELECT 'notas',     COUNT(*) FROM notas;
