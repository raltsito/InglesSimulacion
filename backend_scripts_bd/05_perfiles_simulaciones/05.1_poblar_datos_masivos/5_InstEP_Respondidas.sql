UPDATE ep
SET
    ep.respondida = 1,
    ep.tiempo_consumido_seg = ru.tiempo_respuesta_seg,
    ep.expiro_tiempo = ru.expiro_tiempo
FROM examen_preguntas ep
JOIN respuesta_usuario ru
    ON ep.id_exam_pregunta = ru.id_exam_pregunta
JOIN examenes e
    ON ep.id_examen = e.id_examen
WHERE e.estado = 'EnCurso'
  AND ep.respondida = 0;