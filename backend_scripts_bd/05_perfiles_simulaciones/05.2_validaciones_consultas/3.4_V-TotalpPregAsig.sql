SELECT e.tipo, COUNT(*) AS total_preguntas_asignadas
FROM examen_preguntas ep
JOIN examenes e
  ON ep.id_examen = e.id_examen
GROUP BY e.tipo;