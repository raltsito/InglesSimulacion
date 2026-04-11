/**Promedio por tipo de examen**/
SELECT tipo, CAST(AVG(porcentaje) AS DECIMAL(5,2)) AS promedio
FROM examenes
GROUP BY tipo;