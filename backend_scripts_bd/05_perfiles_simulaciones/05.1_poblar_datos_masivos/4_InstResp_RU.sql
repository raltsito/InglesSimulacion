INSERT INTO respuesta_usuario
(
    id_exam_pregunta,
    respuesta_selec,
    es_correcta,
    tiempo_respuesta_seg,
    expiro_tiempo
)
SELECT
    ep.id_exam_pregunta,

    CASE
        WHEN x.expiro = 1 THEN NULL
        WHEN x.rand_acierto <= x.prob_final THEN p.respuesta_correcta
        ELSE
            CASE p.respuesta_correcta
                WHEN 'A' THEN CHOOSE(1 + ABS(CHECKSUM(NEWID())) % 3, 'B', 'C', 'D')
                WHEN 'B' THEN CHOOSE(1 + ABS(CHECKSUM(NEWID())) % 3, 'A', 'C', 'D')
                WHEN 'C' THEN CHOOSE(1 + ABS(CHECKSUM(NEWID())) % 3, 'A', 'B', 'D')
                WHEN 'D' THEN CHOOSE(1 + ABS(CHECKSUM(NEWID())) % 3, 'A', 'B', 'C')
            END
    END AS respuesta_selec,

    CASE
        WHEN x.expiro = 1 THEN 0
        WHEN x.rand_acierto <= x.prob_final THEN 1
        ELSE 0
    END AS es_correcta,

    CASE
        WHEN x.expiro = 1 THEN 60
        ELSE 10 + ABS(CHECKSUM(NEWID())) % 46
    END AS tiempo_respuesta_seg,

    x.expiro
FROM examen_preguntas ep
JOIN examenes e
    ON ep.id_examen = e.id_examen
JOIN preguntas p
    ON ep.id_pregunta = p.id_pregunta
JOIN perfil_usuario pu
    ON e.id_usuario = pu.id_usuario
LEFT JOIN respuesta_usuario ru
    ON ru.id_exam_pregunta = ep.id_exam_pregunta
OUTER APPLY (
    SELECT COUNT(*) AS practicas_previas
    FROM examenes ex2
    WHERE ex2.id_usuario = e.id_usuario
      AND ex2.tipo = 'Practica'
      AND ex2.estado IN ('Finalizado', 'Cancelado')
) pr
CROSS APPLY (
    SELECT
        CAST((ABS(CHECKSUM(NEWID())) % 1000) / 1000.0 AS DECIMAL(5,3)) AS rand_acierto,

        CASE
            WHEN pu.perfil = 'Bajo' THEN CASE WHEN ABS(CHECKSUM(NEWID())) % 100 < 5 THEN 1 ELSE 0 END
            WHEN pu.perfil = 'Medio' THEN CASE WHEN ABS(CHECKSUM(NEWID())) % 100 < 3 THEN 1 ELSE 0 END
            WHEN pu.perfil = 'Bueno' THEN CASE WHEN ABS(CHECKSUM(NEWID())) % 100 < 1 THEN 1 ELSE 0 END
            ELSE 0
        END AS expiro,

        CASE
            WHEN e.tipo = 'Practica' THEN pu.prob_acierto

            WHEN e.tipo = 'Final' AND pr.practicas_previas >= 3 THEN
                CASE WHEN pu.prob_acierto + 0.08 > 0.98 THEN 0.98 ELSE pu.prob_acierto + 0.08 END

            WHEN e.tipo = 'Final' AND pr.practicas_previas >= 1 THEN
                CASE WHEN pu.prob_acierto + 0.04 > 0.96 THEN 0.96 ELSE pu.prob_acierto + 0.04 END

            ELSE pu.prob_acierto
        END AS prob_final
) x
WHERE e.estado = 'EnCurso'
  AND ru.id_exam_pregunta IS NULL;