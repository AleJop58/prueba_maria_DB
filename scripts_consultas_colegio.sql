USE colegio

--==============
--CONSULTAS
--==============

--Consulta 1: lista a los alumnos activos con su grado y sección. Columnas: apellidos, nombres, grado (“3ro de Secundaria”) y letra. Ordena por grado, luego por letra y luego por apellidos.
--Tablas: alumnos, secciones, grados.

SELECT 
a.apellidos,
a.nombres,
g.nombre AS grado,
s.letra 
FROM alumnos AS a
JOIN secciones AS s
ON a.seccion_id  = s.id 
JOIN grados AS g 
ON s.grado_id  = g.id 
WHERE a.estado = 'Activo'
ORDER BY g.nombre ASC, s.letra ASC, a.apellidos ASC


--Consulta 2: muestra el promedio de notas de cada curso, redondeado a 2 decimales, 
--del más alto al más bajo. Columnas: curso y promedio.
--Pista: ROUND(AVG(...), 2).

SELECT 
C.nombre AS curso,
ROUND(AVG(N.nota ), 2) AS promedio
FROM cursos AS C
JOIN notas AS N
ON N.curso_id  = C.id 
GROUP BY C.nombre 
ORDER BY promedio DESC

--Consulta 3: muestra a los profesores que no dictan ningún curso. Columnas: nombres, apellidos y especialidad.
--Pista: LEFT JOIN con dictado + IS NULL.}
SELECT 
p.nombres,
p.apellidos,
p.especialidad 
FROM profesores AS p
LEFT JOIN dictado AS d
ON d.profesor_id  = p.id 
WHERE d.profesor_id  IS NULL

--Muestra a los alumnos cuyo promedio general es mayor que el promedio de todas las notas del colegio.
SELECT 
a.apellidos ,
a.nombres ,
ROUND(AVG(n.nota), 2) as promedio
FROM alumnos AS a
JOIN notas AS n
ON n.alumno_id  = a.id 
GROUP BY a.apellidos , a.nombres
HAVING promedio > (SELECT AVG(nota) FROM notas)
ORDER BY promedio DESC


--==============
--FUNCIONES
--==============

--Crea una función que reciba el id de un alumno y devuelva su promedio general 
--(de todas sus notas, en todos los cursos y bimestres).

CREATE FUNCTION fn_promedio_alumno(p_alumno_id INT)
RETURNS DECIMAL(4,2)
READS SQL DATA
BEGIN
	DECLARE v_promedio DECIMAL(4,2);
	SELECT AVG(nota) INTO v_promedio
    FROM notas
    WHERE alumno_id = p_alumno_id;
	RETURN v_promedio;
END;

SELECT nombres, fn_promedio_alumno(id) FROM alumnos WHERE id = 3;

--Crea una función que reciba una nota (de 0 a 20) y devuelva la calificación tipo libreta
CREATE OR REPLACE FUNCTION fn_calificacion(p_nota DECIMAL(4,2))
RETURNS VARCHAR(2)
DETERMINISTIC
BEGIN
    DECLARE v_calificacion VARCHAR(2);

    IF p_nota >= 18 THEN
        SET v_calificacion = 'AD';
    ELSEIF p_nota >= 14 THEN
        SET v_calificacion = 'A';
    ELSEIF p_nota >= 11 THEN
        SET v_calificacion = 'B';
    ELSE
        SET v_calificacion = 'C';
    END IF;

    RETURN v_calificacion;
END;

SELECT fn_calificacion(19), fn_calificacion(15), fn_calificacion(14.1), fn_calificacion(8);

--==============
--PROCEDIMIENTOS ALMACENADOS
--==============


--Crea un procedimiento que reciba el id de una sección y muestre a sus alumnos activos
CREATE OR REPLACE PROCEDURE sp_reporte_seccion(IN p_seccion_id INT)
BEGIN
    SELECT
    a.nombres,
    a.apellidos,
    (SELECT fn_promedio_alumno(a.id)) AS Promedio,
    (SELECT fn_calificacion(fn_promedio_alumno(a.id))) AS calificacion
    FROM alumnos AS a
    WHERE a.seccion_id = p_seccion_id AND
    a.estado = 'Activo'
    ORDER BY Promedio DESC;
END;

CALL sp_reporte_seccion(3);
CALL sp_reporte_seccion(1)


--Recibe 4 parámetros: p_alumno_id, p_curso_id, p_bimestre y p_nota. Y debe
--Verificar que el alumno exista y esté activo. Si no, mostrar un error y no insertar nada.
--Verificar que la nota esté entre 0 y 20 y el bimestre entre 1 y 4.
--Insertar la nota con la fecha de hoy (CURDATE()).
--Mostrar el mensaje “Nota registrada correctamente”.
CREATE OR REPLACE PROCEDURE sp_registrar_nota(
    IN p_alumno_id INT,
    IN p_curso_id  INT,
    IN p_bimestre  TINYINT,
    IN p_nota      DECIMAL(4,2)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM alumnos
        WHERE id = p_alumno_id AND estado = 'Activo'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El alumno no existe o está retirado';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM cursos WHERE id = p_curso_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El curso no existe';
    END IF;

    IF p_nota < 0 OR p_nota > 20 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La nota debe estar entre 0 y 20';
    END IF;

    IF p_bimestre < 1 OR p_bimestre > 4 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El bimestre debe estar entre 1 y 4';
    END IF;

    INSERT INTO notas (alumno_id, curso_id, bimestre, nota, fecha_registro)
    VALUES (p_alumno_id, p_curso_id, p_bimestre, p_nota, CURDATE());

    SELECT 'Nota registrada correctamente' AS resultado;
END;

CALL sp_registrar_nota(1, 1, 4, 17.5);
CALL sp_registrar_nota(1, 2, 4, 25);

--==============
--INDICE
--==============

--Crea indice de busqueda por apellidos

EXPLAIN SELECT * FROM alumnos WHERE apellidos LIKE 'C%';
CREATE INDEX idx_alumnos_apellidos ON alumnos(apellidos);
SHOW INDEX FROM alumnos;
EXPLAIN SELECT * FROM alumnos WHERE apellidos LIKE 'C%';

