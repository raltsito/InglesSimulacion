SELECT respondida, COUNT(*) AS total
FROM examen_preguntas
GROUP BY respondida;