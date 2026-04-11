/**Validaciones**/
--Inconsistencia
SELECT COUNT(*) AS inconsistentes
FROM examenes
WHERE (aciertos + errores) <> total_preguntas;

--Sin historial
SELECT COUNT(*) AS sin_historial
FROM examenes e
LEFT JOIN historial_estudiante h
    ON e.id_examen = h.id_examen
WHERE e.estado = 'Finalizado'
  AND h.id_examen IS NULL;