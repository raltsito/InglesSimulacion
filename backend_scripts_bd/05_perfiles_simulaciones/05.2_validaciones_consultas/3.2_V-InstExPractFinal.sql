SELECT estado, tipo, COUNT(*) AS total
FROM examenes
GROUP BY estado, tipo
ORDER BY estado, tipo;