SELECT 
    COUNT(*) AS total,
    SUM(CASE WHEN es_correcta = 1 THEN 1 ELSE 0 END) AS correctas,
    CAST(100.0 * SUM(CASE WHEN es_correcta = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS porcentaje_correctas
FROM respuesta_usuario;