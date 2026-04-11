SELECT estado, COUNT(*) AS total
FROM examenes
GROUP BY estado;