SELECT total_preguntas, COUNT(*) AS total
FROM examenes
GROUP BY total_preguntas;