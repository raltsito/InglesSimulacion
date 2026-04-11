SELECT aprobado, COUNT(*) AS total
FROM examenes
GROUP BY aprobado;

SELECT nivel_obtenido, COUNT(*) AS total
FROM examenes
GROUP BY nivel_obtenido;

SELECT tipo, CAST(AVG(porcentaje) AS DECIMAL(5,2)) AS promedio
FROM examenes
GROUP BY tipo;

SELECT COUNT(*) AS inconsistentes
FROM examenes
WHERE (aciertos + errores) <> total_preguntas;

SELECT COUNT(*) AS sin_historial
FROM examenes e
LEFT JOIN historial_estudiante h
    ON e.id_examen = h.id_examen
WHERE e.estado = 'Finalizado'
  AND h.id_examen IS NULL;