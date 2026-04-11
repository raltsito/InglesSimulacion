DELETE FROM historial_estudiante;
DELETE FROM respuesta_usuario;
DELETE FROM examen_preguntas;
DELETE FROM examenes;

UPDATE usuarios
SET intentos_practica = 0,
    intentos_final = 0;