SELECT perfil, COUNT(*) AS total, AVG(prob_acierto) AS prom_prob
FROM perfil_usuario
GROUP BY perfil;