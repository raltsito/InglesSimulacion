USE [SimuladorIngles]
GO

/****** Object:  StoredProcedure [dbo].[sp_poblar_datos_demo_fast]    Script Date: 15/4/2026 10:46:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[sp_poblar_datos_demo_fast]
    @usuarios_a_simular INT = 1000,
    @practicas_por_usuario INT = 3,
    @finales_por_usuario INT = 1,
    @limpiar_datos_previos BIT = 1,
    @solo_usuarios_demo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @usuarios_a_simular <= 0
    BEGIN
        RAISERROR('usuarios_a_simular debe ser mayor a 0.', 16, 1);
        RETURN;
    END;

    IF @practicas_por_usuario < 0 OR @practicas_por_usuario > 5
    BEGIN
        RAISERROR('practicas_por_usuario debe estar entre 0 y 5.', 16, 1);
        RETURN;
    END;

    IF @finales_por_usuario < 0 OR @finales_por_usuario > 2
    BEGIN
        RAISERROR('finales_por_usuario debe estar entre 0 y 2.', 16, 1);
        RETURN;
    END;

    -- 1 Limpiar datos previos

    IF @limpiar_datos_previos = 1
    BEGIN
        DELETE FROM dbo.historial_estudiante;
        DELETE FROM dbo.respuesta_usuario;
        DELETE FROM dbo.examen_preguntas;
        DELETE FROM dbo.examenes;

        UPDATE dbo.usuarios
        SET intentos_practica = 0,
            intentos_final = 0
        WHERE (@solo_usuarios_demo = 0)
           OR (@solo_usuarios_demo = 1 AND matricula LIKE 'DEMO%');

        DELETE pu
        FROM dbo.perfil_usuario pu
        INNER JOIN dbo.usuarios u
            ON u.id_usuario = pu.id_usuario
        WHERE (@solo_usuarios_demo = 0)
           OR (@solo_usuarios_demo = 1 AND u.matricula LIKE 'DEMO%');
    END;

--- Usuarios

    IF OBJECT_ID('tempdb..#UsuariosObjetivo') IS NOT NULL DROP TABLE #UsuariosObjetivo;
    CREATE TABLE #UsuariosObjetivo
    (
        id_usuario INT PRIMARY KEY
    );

    INSERT INTO #UsuariosObjetivo (id_usuario)
    SELECT TOP (@usuarios_a_simular) u.id_usuario
    FROM dbo.usuarios u
    WHERE u.activo = 1
      AND (
            @solo_usuarios_demo = 0
            OR (@solo_usuarios_demo = 1 AND u.matricula LIKE 'DEMO%')
          )
    ORDER BY u.id_usuario;

    IF NOT EXISTS (SELECT 1 FROM #UsuariosObjetivo)
    BEGIN
        RAISERROR('No hay usuarios objetivo.', 16, 1);
        RETURN;
    END;

    --- 3 Perfiles de usuario

    INSERT INTO dbo.perfil_usuario (id_usuario, perfil, prob_acierto)
    SELECT
        t.id_usuario,
        CASE
            WHEN r.rn < 20 THEN 'Bajo'
            WHEN r.rn < 55 THEN 'Medio'
            WHEN r.rn < 85 THEN 'Bueno'
            ELSE 'MuyBueno'
        END,
        CASE
            WHEN r.rn < 20 THEN 0.45
            WHEN r.rn < 55 THEN 0.65
            WHEN r.rn < 85 THEN 0.80
            ELSE 0.92
        END
    FROM #UsuariosObjetivo t
    CROSS APPLY (SELECT ABS(CHECKSUM(NEWID())) % 100 AS rn) r;

    -- 4 Tabla de números local

    IF OBJECT_ID('tempdb..#Nums') IS NOT NULL DROP TABLE #Nums;
    CREATE TABLE #Nums (n INT PRIMARY KEY);

    ;WITH x AS
    (
        SELECT TOP (10)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects
    )
    INSERT INTO #Nums(n)
    SELECT n FROM x;

    -- 5 Crear exámenes en lote

    IF OBJECT_ID('tempdb..#ExamenesNuevos') IS NOT NULL DROP TABLE #ExamenesNuevos;
    CREATE TABLE #ExamenesNuevos
    (
        id_examen INT PRIMARY KEY,
        id_usuario INT,
        tipo VARCHAR(20)
    );

    -- Prácticas
    IF @practicas_por_usuario > 0
    BEGIN
        INSERT INTO dbo.examenes
        (
            id_usuario,
        tipo,
        fecha_inicio,
        tiempo_pregunta_seg,
        total_preguntas,
        aciertos,
        errores,
        porcentaje,
        aprobado,
        nivel_obtenido,
        estado
        )
        OUTPUT inserted.id_examen, inserted.id_usuario, inserted.tipo
        INTO #ExamenesNuevos(id_examen, id_usuario, tipo)
        SELECT
            uo.id_usuario,
        'Practica',
        DATEADD(SECOND, ABS(CHECKSUM(NEWID())) % 5000, GETDATE()),
        60,
        20,
        0,
        0,
        0,
        0,
        NULL,
        'EnCurso'
        FROM #UsuariosObjetivo uo
        INNER JOIN #Nums n
            ON n.n <= @practicas_por_usuario;
    END;

    -- Finales
    IF @finales_por_usuario > 0
    BEGIN
        INSERT INTO dbo.examenes
        (
            id_usuario,
        tipo,
        fecha_inicio,
        tiempo_pregunta_seg,
        total_preguntas,
        aciertos,
        errores,
        porcentaje,
        aprobado,
        nivel_obtenido,
        estado
        )
        OUTPUT inserted.id_examen, inserted.id_usuario, inserted.tipo
        INTO #ExamenesNuevos(id_examen, id_usuario, tipo)
        SELECT
            uo.id_usuario,
        'Final',
        DATEADD(SECOND, ABS(CHECKSUM(NEWID())) % 5000, GETDATE()),
        60,
        40,
        0,
        0,
        0,
        0,
        NULL,
        'EnCurso'
        FROM #UsuariosObjetivo uo
        INNER JOIN #Nums n
            ON n.n <= @finales_por_usuario;
    END;

    --- 6 Actualizar intentos por lote

    UPDATE u
    SET intentos_practica = intentos_practica + @practicas_por_usuario,
        intentos_final = intentos_final + @finales_por_usuario
    FROM dbo.usuarios u
    INNER JOIN #UsuariosObjetivo t
        ON t.id_usuario = u.id_usuario;

---- 7 Preguntas aleatorias por examen

    IF OBJECT_ID('tempdb..#PoolPreguntas') IS NOT NULL DROP TABLE #PoolPreguntas;
    CREATE TABLE #PoolPreguntas
    (
        id_examen INT,
        id_pregunta INT,
        numero_orden INT
    );

    ;WITH PreguntasRankeadas AS
    (
        SELECT
            e.id_examen,
            e.tipo,
            p.id_pregunta,
            ROW_NUMBER() OVER
            (
                PARTITION BY e.id_examen
                ORDER BY CHECKSUM(NEWID(), e.id_examen, p.id_pregunta)
            ) AS rn
        FROM #ExamenesNuevos e
        CROSS JOIN dbo.preguntas p
        WHERE p.activa = 1
    )
    INSERT INTO #PoolPreguntas(id_examen, id_pregunta, numero_orden)
    SELECT
        id_examen,
        id_pregunta,
        rn
    FROM PreguntasRankeadas
    WHERE (tipo = 'Practica' AND rn <= 20)
       OR (tipo = 'Final' AND rn <= 40);
    
    --- 8 Insertar examen_preguntas

    INSERT INTO dbo.examen_preguntas
    (
        id_examen,
        id_pregunta,
        numero_orden,
        respondida,
        tiempo_consumido_seg,
        expiro_tiempo
    )
    SELECT
        id_examen,
        id_pregunta,
        numero_orden,
        0,
        0,
        0
    FROM #PoolPreguntas;

    --- 9 Generar respuestas

    INSERT INTO dbo.respuesta_usuario
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
            WHEN calc.expiro = 1 THEN NULL
            WHEN calc.rand_acierto <= calc.prob_final THEN p.respuesta_correcta
            ELSE
                CASE p.respuesta_correcta
                    WHEN 'A' THEN CHOOSE(1 + ABS(CHECKSUM(NEWID())) % 3, 'B', 'C', 'D')
                    WHEN 'B' THEN CHOOSE(1 + ABS(CHECKSUM(NEWID())) % 3, 'A', 'C', 'D')
                    WHEN 'C' THEN CHOOSE(1 + ABS(CHECKSUM(NEWID())) % 3, 'A', 'B', 'D')
                    WHEN 'D' THEN CHOOSE(1 + ABS(CHECKSUM(NEWID())) % 3, 'A', 'B', 'C')
                END
        END AS respuesta_selec,
        CASE
            WHEN calc.expiro = 1 THEN 0
            WHEN calc.rand_acierto <= calc.prob_final THEN 1
            ELSE 0
        END AS es_correcta,
        CASE
            WHEN calc.expiro = 1 THEN 60
            ELSE 10 + ABS(CHECKSUM(NEWID())) % 46
        END AS tiempo_respuesta_seg,
        calc.expiro
    FROM dbo.examen_preguntas ep
    INNER JOIN #ExamenesNuevos e
        ON e.id_examen = ep.id_examen
    INNER JOIN dbo.preguntas p
        ON p.id_pregunta = ep.id_pregunta
    INNER JOIN dbo.perfil_usuario pu
        ON pu.id_usuario = e.id_usuario
    CROSS APPLY
    (
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
                WHEN e.tipo = 'Final' AND @practicas_por_usuario >= 3 THEN
                    CASE WHEN pu.prob_acierto + 0.08 > 0.98 THEN 0.98 ELSE pu.prob_acierto + 0.08 END
                WHEN e.tipo = 'Final' AND @practicas_por_usuario >= 1 THEN
                    CASE WHEN pu.prob_acierto + 0.04 > 0.96 THEN 0.96 ELSE pu.prob_acierto + 0.04 END
                ELSE pu.prob_acierto
            END AS prob_final
    ) calc;

    --- 10 Marcar respondidas

    UPDATE ep
    SET
        ep.respondida = 1,
        ep.tiempo_consumido_seg = ru.tiempo_respuesta_seg,
        ep.expiro_tiempo = ru.expiro_tiempo
    FROM dbo.examen_preguntas ep
    INNER JOIN dbo.respuesta_usuario ru
        ON ru.id_exam_pregunta = ep.id_exam_pregunta
    INNER JOIN #ExamenesNuevos e
        ON e.id_examen = ep.id_examen;

    -- 11 Calificar

    ;WITH Resumen AS
    (
        SELECT
            e.id_examen,
            e.tipo,
            COUNT(*) AS total_preguntas,
            SUM(CASE WHEN ru.es_correcta = 1 THEN 1 ELSE 0 END) AS aciertos,
            SUM(CASE WHEN ru.es_correcta = 0 THEN 1 ELSE 0 END) AS errores
        FROM #ExamenesNuevos e
        INNER JOIN dbo.examen_preguntas ep
            ON ep.id_examen = e.id_examen
        INNER JOIN dbo.respuesta_usuario ru
            ON ru.id_exam_pregunta = ep.id_exam_pregunta
        GROUP BY e.id_examen, e.tipo
    )
    UPDATE ex
    SET
        ex.fecha_fin = GETDATE(),
        ex.estado = 'Finalizado',
        ex.aciertos = r.aciertos,
        ex.errores = r.errores,
        ex.total_preguntas = r.total_preguntas,
        ex.porcentaje =
            CASE
                WHEN r.tipo = 'Practica' THEN (r.aciertos * 100.0) / 20.0
                WHEN r.tipo = 'Final' THEN (r.aciertos * 100.0) / 40.0
            END,
        ex.aprobado =
            CASE
                WHEN (
                    CASE
                        WHEN r.tipo = 'Practica' THEN (r.aciertos * 100.0) / 20.0
                        WHEN r.tipo = 'Final' THEN (r.aciertos * 100.0) / 40.0
                    END
                ) >= 70 THEN 1 ELSE 0
            END,
        ex.nivel_obtenido =
            CASE
                WHEN (
                    CASE
                        WHEN r.tipo = 'Practica' THEN (r.aciertos * 100.0) / 20.0
                        WHEN r.tipo = 'Final' THEN (r.aciertos * 100.0) / 40.0
                    END
                ) < 70 THEN 'No Aprobado'
                WHEN (
                    CASE
                        WHEN r.tipo = 'Practica' THEN (r.aciertos * 100.0) / 20.0
                        WHEN r.tipo = 'Final' THEN (r.aciertos * 100.0) / 40.0
                    END
                ) < 80 THEN 'Basico'
                WHEN (
                    CASE
                        WHEN r.tipo = 'Practica' THEN (r.aciertos * 100.0) / 20.0
                        WHEN r.tipo = 'Final' THEN (r.aciertos * 100.0) / 40.0
                    END
                ) < 90 THEN 'Intermedio'
                ELSE 'Avanzado'
            END
    FROM dbo.examenes ex
    INNER JOIN Resumen r
        ON r.id_examen = ex.id_examen;

    --- 12 Historial

    INSERT INTO dbo.historial_estudiante
    (
        id_usuario,
        id_examen,
        tipo_examen,
        puntaje,
        porcentaje,
        aprobado,
        nivel_obtenido,
        fecha
    )
    SELECT
        e.id_usuario,
        e.id_examen,
        e.tipo,
        CASE
            WHEN e.tipo = 'Practica' THEN e.aciertos * 5.0
            WHEN e.tipo = 'Final' THEN e.aciertos * 2.5
        END AS puntaje,
        e.porcentaje,
        e.aprobado,
        e.nivel_obtenido,
        e.fecha_fin
    FROM dbo.examenes e
    INNER JOIN #ExamenesNuevos n
        ON n.id_examen = e.id_examen
    LEFT JOIN dbo.historial_estudiante h
        ON h.id_examen = e.id_examen
    WHERE h.id_examen IS NULL;

    --- 13 Resultados
    SELECT
        (SELECT COUNT(*) FROM #UsuariosObjetivo) AS usuarios_simulados,
        (SELECT COUNT(*) FROM #ExamenesNuevos WHERE tipo = 'Practica') AS examenes_practica,
        (SELECT COUNT(*) FROM #ExamenesNuevos WHERE tipo = 'Final') AS examenes_final,
        (SELECT COUNT(*) 
         FROM dbo.respuesta_usuario ru
         INNER JOIN dbo.examen_preguntas ep ON ep.id_exam_pregunta = ru.id_exam_pregunta
         INNER JOIN #ExamenesNuevos e ON e.id_examen = ep.id_examen) AS respuestas_generadas;
END;
GO


