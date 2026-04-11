DELETE FROM perfil_usuario;

INSERT INTO perfil_usuario (id_usuario, perfil, prob_acierto)
SELECT
    u.id_usuario,
    CASE
        WHEN r.rn < 20 THEN 'Bajo'
        WHEN r.rn < 55 THEN 'Medio'
        WHEN r.rn < 85 THEN 'Bueno'
        ELSE 'MuyBueno'
    END AS perfil,
    CASE
        WHEN r.rn < 20 THEN 0.45
        WHEN r.rn < 55 THEN 0.65
        WHEN r.rn < 85 THEN 0.80
        ELSE 0.92
    END AS prob_acierto
FROM usuarios u
CROSS APPLY (
    SELECT ABS(CHECKSUM(NEWID())) % 100 AS rn
) r;