;WITH resultados AS
(
    SELECT
        e.id_examen,
        e.id_usuario,
        e.tipo,
        e.total_preguntas,
        SUM(CASE WHEN ru.es_correcta = 1 THEN 1 ELSE 0 END) AS aciertos
    FROM examenes e
    JOIN examen_preguntas ep
        ON e.id_examen = ep.id_examen
    LEFT JOIN respuesta_usuario ru
        ON ep.id_exam_pregunta = ru.id_exam_pregunta
    WHERE e.estado = 'EnCurso'
    GROUP BY
        e.id_examen,
        e.id_usuario,
        e.tipo,
        e.total_preguntas
),
final_calc AS
(
    SELECT
        id_examen,
        id_usuario,
        tipo,
        total_preguntas,
        ISNULL(aciertos, 0) AS aciertos,
        total_preguntas - ISNULL(aciertos, 0) AS errores,
        CAST((ISNULL(aciertos, 0) * 100.0) / total_preguntas AS DECIMAL(5,2)) AS porcentaje,
        CAST(CASE WHEN ((ISNULL(aciertos, 0) * 100.0) / total_preguntas) >= 70 THEN 1 ELSE 0 END AS BIT) AS aprobado,
        CASE
            WHEN ((ISNULL(aciertos, 0) * 100.0) / total_preguntas) < 70 THEN 'No Aprobado'
            WHEN ((ISNULL(aciertos, 0) * 100.0) / total_preguntas) < 80 THEN 'Basico'
            WHEN ((ISNULL(aciertos, 0) * 100.0) / total_preguntas) < 90 THEN 'Intermedio'
            ELSE 'Avanzado'
        END AS nivel_obtenido
    FROM resultados
)
UPDATE e
SET
    e.fecha_fin = GETDATE(),
    e.aciertos = f.aciertos,
    e.errores = f.errores,
    e.porcentaje = f.porcentaje,
    e.aprobado = f.aprobado,
    e.nivel_obtenido = f.nivel_obtenido,
    e.estado = 'Finalizado'
FROM examenes e
JOIN final_calc f
    ON e.id_examen = f.id_examen;