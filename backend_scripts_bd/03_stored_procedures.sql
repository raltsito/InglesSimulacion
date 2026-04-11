CREATE   PROCEDURE [dbo].[sp_calificar_examen]
	@id_examen INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @tipo VARCHAR(20);
	DECLARE @id_usuario INT;
	DECLARE @total_preguntas INT;
	DECLARE @aciertos INT;
	DECLARE @errores INT;
	DECLARE @porcentaje DECIMAL(5,2);
	DECLARE @aprobado BIT;
	DECLARE @nivel_obtenido VARCHAR(20);

	SELECT
		@tipo = tipo,
		@id_usuario = id_usuario,
		@total_preguntas = total_preguntas
	FROM examenes
	WHERE id_examen = @id_examen;

	IF @tipo IS NULL
	BEGIN
		RAISERROR('El examen no existe',16,1);
		RETURN;
	END

	SELECT @aciertos =  COUNT(*)
	FROM respuesta_usuario ru
	INNER JOIN examen_preguntas ep
		ON ru.id_exam_pregunta = ep.id_exam_pregunta
	WHERE ep.id_examen = @id_examen
		AND ru.es_correcta = 1;
	
	SET @aciertos = ISNULL(@aciertos, 0);
	SET @errores = @total_preguntas - @aciertos;

	SET @porcentaje = CAST((@aciertos * 100.0) / @total_preguntas AS DECIMAL(5,2));

	SET @aprobado = CASE WHEN @porcentaje >= 70 THEN 1 ELSE 0 END;

	SET @nivel_obtenido =
		CASE
			WHEN @porcentaje < 70 THEN 'No Aprobado'
			WHEN @porcentaje >= 70 AND @porcentaje < 80 THEN 'Basico'
			WHEN @porcentaje >= 80 AND @porcentaje < 90 THEN 'Intermedio'
			WHEN @porcentaje >= 90 THEN 'Avanzado'
		END;
	UPDATE examenes
	SET
		fecha_fin = GETDATE(),
		aciertos = @aciertos,
		errores = @errores,
		porcentaje = @porcentaje,
		aprobado = @aprobado,
		nivel_obtenido = @nivel_obtenido,
		estado = 'Finalizado'
	WHERE id_examen = @id_examen;

	IF NOT EXISTS (
        SELECT 1
        FROM historial_estudiante
        WHERE id_examen = @id_examen
    )
    BEGIN
        INSERT INTO historial_estudiante (
            id_usuario,
            id_examen,
            tipo_examen,
            fecha,
            puntaje,
            porcentaje,
            aprobado,
            nivel_obtenido
        )
        VALUES (
            @id_usuario,
            @id_examen,
            @tipo,
            GETDATE(),
            @aciertos,
            @porcentaje,
            @aprobado,
            @nivel_obtenido
        );
    END;

	SELECT
		@id_examen AS id_examen,
		@tipo AS tipo,
		@aciertos AS aciertos,
		@errores AS errores,
		@porcentaje AS porcentaje,
		@aprobado AS aprobado,
		@nivel_obtenido AS nivel_obtenido;
END;
GO

CREATE   PROCEDURE [dbo].[sp_cancelar_examen]
    @id_examen INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_usuario INT;
    DECLARE @tipo VARCHAR(20);
    DECLARE @estado VARCHAR(20);

    SELECT
        @id_usuario = id_usuario,
        @tipo = tipo,
        @estado = estado
    FROM examenes
    WHERE id_examen = @id_examen;

    IF @id_usuario IS NULL
    BEGIN
        RAISERROR('El examen no existe.', 16, 1);
        RETURN;
    END

    IF @estado <> 'EnCurso'
    BEGIN
        RAISERROR('Solo se pueden cancelar exámenes en curso.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    BEGIN TRY
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
            NULL,
            0,
            0,
            0
        FROM examen_preguntas ep
        LEFT JOIN respuesta_usuario ru
            ON ru.id_exam_pregunta = ep.id_exam_pregunta
        WHERE ep.id_examen = @id_examen
          AND ru.id_exam_pregunta IS NULL;

        UPDATE ep
        SET
            respondida = 1,
            tiempo_consumido_seg = 0,
            expiro_tiempo = 0
        FROM examen_preguntas ep
        WHERE ep.id_examen = @id_examen
          AND ep.respondida = 0;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH

    EXEC sp_calificar_examen @id_examen=@id_examen;

    UPDATE examenes
    SET
        estado = 'Cancelado',
        aprobado = 0,
        nivel_obtenido = 'No Aprobado'
    WHERE id_examen = @id_examen;
        
    UPDATE historial_estudiante
    SET
        aprobado = 0,
        nivel_obtenido = 'No Aprobado'
    WHERE id_examen = @id_examen;

    SELECT
        id_examen,
        id_usuario,
        tipo,
        estado,
        total_preguntas,
        aciertos,
        errores,
        porcentaje,
        aprobado,
        nivel_obtenido,
        fecha_inicio,
        fecha_fin
    FROM examenes
    WHERE id_examen = @id_examen;
END;
GO

CREATE   PROCEDURE [dbo].[sp_crear_exam_final]
	@id_usuario INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @intentos_actuales INT;
	DECLARE @id_examen INT;

	IF NOT EXISTS (
        SELECT 1
        FROM usuarios
        WHERE id_usuario = @id_usuario
    )
    BEGIN
        RAISERROR('El usuario no existe', 16, 1);
        RETURN;
    END

	IF EXISTS (
        SELECT 1
        FROM examenes
        WHERE id_usuario = @id_usuario
          AND tipo = 'Final'
          AND estado = 'EnCurso'
    )
    BEGIN
        RAISERROR('El usuario ya tiene un examen final en curso', 16, 1);
        RETURN;
    END

	SELECT @intentos_actuales = COUNT(*)
    FROM examenes
    WHERE id_usuario = @id_usuario
      AND tipo = 'Final';

    IF @intentos_actuales >= 2
    BEGIN
        RAISERROR('El usuario ya alcanzó el máximo de 2 intentos finales', 16, 1);
        RETURN;
    END

	IF (SELECT COUNT(*) FROM preguntas WHERE activa = 1) < 40
	BEGIN
		RAISERROR('No hay suficientes preguntas activas para generar el examen final',16,1);
		RETURN;
	END

	BEGIN TRANSACTION

	BEGIN TRY
		INSERT INTO examenes (
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
		VALUES (
			@id_usuario,
			'Final',
			GETDATE(),
			60,
			40,
			0,
			0,
			0,
			0,
			NULL,
			'EnCurso'
		);

		SET @id_examen = SCOPE_IDENTITY();

		;WITH preguntas_aleatorias AS (
			SELECT TOP 40
				id_pregunta,
				ROW_NUMBER() OVER (ORDER BY NEWID()) AS numero_orden
			FROM preguntas
			WHERE activa = 1
			ORDER BY NEWID()
		)
		INSERT INTO examen_preguntas (
			id_examen,
			id_pregunta,
			numero_orden,
			respondida,
			tiempo_consumido_seg,
			expiro_tiempo
		)
		SELECT
			@id_examen,
			id_pregunta,
			numero_orden,
			0,
			0,
			0
		FROM preguntas_aleatorias;

		UPDATE usuarios
		SET intentos_final = intentos_final + 1
		WHERE id_usuario = @id_usuario;

		COMMIT TRANSACTION;

		SELECT @id_examen AS id_examen_generado;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END;
GO

CREATE   PROCEDURE [dbo].[sp_crear_exam_practica]
	@id_usuario INT
AS 
	BEGIN
		SET NOCOUNT ON;

		DECLARE @intentos_actuales INT;
		DECLARE @id_examen INT;

		IF NOT EXISTS (
			SELECT 1
			FROM usuarios
			WHERE id_usuario = @id_usuario
		)
		BEGIN
			RAISERROR('El usuario no existe', 16, 1);
			RETURN;
		END

		IF EXISTS (
			SELECT 1
			FROM examenes
			WHERE id_usuario = @id_usuario
				AND tipo = 'Practica'
				AND estado = 'EnCurso'
		)
		BEGIN
			RAISERROR('El usuario ya tiene un examen de práctica en curso', 16, 1);
			RETURN;
		END

		SELECT @intentos_actuales = COUNT(*)
		FROM examenes
		WHERE id_usuario = @id_usuario
			AND tipo = 'Practica';

		IF @intentos_actuales >= 5
		BEGIN
			RAISERROR('El usuario ya alcanzó el máximo de 5 intentos de práctica', 16, 1);
			RETURN;
		END

		IF (SELECT COUNT(*) FROM preguntas WHERE activa = 1) < 20
		BEGIN
			RAISERROR('No hay suficientes preguntas activas para generar el examen de práctica', 16, 1);
			RETURN;
		END

		BEGIN TRANSACTION;

		BEGIN TRY
			INSERT INTO examenes (
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
			VALUES (
				@id_usuario,
				'Practica',
				GETDATE(),
				60,
				20,
				0,
				0,
				0,
				0,
				NULL,
				'EnCurso'
			);

			SET @id_examen = SCOPE_IDENTITY();

			;WITH preguntas_aleatorias AS (
				SELECT TOP 20
					id_pregunta,
					ROW_NUMBER() OVER (ORDER BY NEWID()) AS numero_orden
				FROM preguntas
				WHERE activa = 1
				ORDER BY NEWID()
			)
			INSERT INTO examen_preguntas (
				id_examen,
				id_pregunta,
				numero_orden,
				respondida,
				tiempo_consumido_seg,
				expiro_tiempo
			)
			SELECT
				@id_examen,
				id_pregunta,
				numero_orden,
				0,
				0,
				0
			FROM preguntas_aleatorias;

			UPDATE usuarios
			SET intentos_practica = intentos_practica + 1
			WHERE id_usuario = @id_usuario;

			COMMIT TRANSACTION;

			SELECT @id_examen AS id_examen_generado;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END;
GO

CREATE   PROCEDURE [dbo].[sp_expirar_pregunta]
	@id_exam_pregunta INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ya_respondida BIT;

	SELECT @ya_respondida = respondida
	FROM examen_perguntas
	WHERE id_exam_pregunta = @id_exam_pregunta;

	IF @ya_respondida IS NULL
	BEGIN
		RAISERROR('No existe la pregunta del examen',16,1);
		RETURN;
	END

	IF @ya_respondida = 1
	BEGIN
		RAISERROR('La pregunta fue respondida o expirada', 16,1);
		RETURN;
	END

	INSERT INTO repsuesta_usuario (
		id_exam_pregunta,
		respuesta_selec,
		es_correcta,
		tiempo_respuesta_seg,
		expiro_tiempo
	)
	VALUES (
		@id_exam_pregunta,
		NULL,
		0,
		60,
		1
	);

	UPDATE examen_preguntas
	SET
		respondida = 1,
		tiempo_consumido_seg = 60,
		expiro_tiempo = 1
	WHERE id_exam_pregunta = @id_exam_pregunta;
END;
GO

CREATE   PROCEDURE [dbo].[sp_obtener_sig_preg]
	@id_examen INT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT TOP 1
		ep.id_exam_pregunta,
		ep.numero_orden,
		p.id_pregunta,
		p.enunciado,
		p.opcion_a,
		p.opcion_b,
		p.opcion_c,
		p.opcion_d,
		p.nivel,
		p.materia,
		p.id_imagen
	FROM examen_preguntas ep
	INNER JOIN preguntas p
		ON ep.id_pregunta = p.id_pregunta
	WHERE ep.id_examen = @id_examen
		AND ep.respondida = 0
	ORDER BY ep.numero_orden;
END;
GO

CREATE   PROCEDURE [dbo].[sp_registrar_respuestas]
	@id_exam_pregunta INT,
	@respuesta_seleccionada CHAR(1),
	@tiempo_respuesta_seg INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @respuesta_correcta CHAR(1);
	DECLARE @ya_respondida BIT;

	SELECT
		@respuesta_correcta = p.respuesta_correcta,
		@ya_respondida = ep.respondida
	FROM examen_preguntas ep
	INNER JOIN preguntas p ON ep.id_pregunta = p.id_pregunta
	WHERE ep.id_exam_pregunta = @id_exam_pregunta;

	IF @respuesta_correcta IS NULL
	BEGIN
		RAISERROR('No existe la pregunta asignada al examen',16,1);
		RETURN;
	END

	IF @ya_respondida = 1
	BEGIN
		RAISERROR('Esta pregunta ya fue respondida',16,1);
		RETURN;
	END

	INSERT INTO respuesta_usuario (
		id_exam_pregunta,
		respuesta_selec,
		es_correcta,
		tiempo_respuesta_seg,
		expiro_tiempo
	)
	VALUES (
		@id_exam_pregunta,
		@respuesta_seleccionada,
		CASE WHEN @respuesta_seleccionada = @respuesta_correcta THEN 1 ELSE 0 END,
		@tiempo_respuesta_seg,
		0
	);
	UPDATE examen_preguntas
	SET
		respondida = 1,
		tiempo_consumido_seg = @tiempo_respuesta_seg,
		expiro_tiempo = 0
	WHERE id_exam_pregunta = @id_exam_pregunta;
END;
GO
