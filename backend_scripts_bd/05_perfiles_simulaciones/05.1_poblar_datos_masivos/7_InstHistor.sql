INSERT INTO historial_estudiante
(
    id_usuario,
    id_examen,
    tipo_examen,
    fecha,
    puntaje,
    porcentaje,
    aprobado,
    nivel_obtenido
)
SELECT
    e.id_usuario,
    e.id_examen,
    e.tipo,
    GETDATE(),
    e.aciertos,
    e.porcentaje,
    e.aprobado,
    e.nivel_obtenido
FROM examenes e
LEFT JOIN historial_estudiante h
    ON e.id_examen = h.id_examen
WHERE e.estado = 'Finalizado'
  AND h.id_examen IS NULL;