/** Niveles de Ingles **/
SELECT nivel_obtenido, COUNT(*) AS total
FROM examenes
GROUP BY nivel_obtenido;