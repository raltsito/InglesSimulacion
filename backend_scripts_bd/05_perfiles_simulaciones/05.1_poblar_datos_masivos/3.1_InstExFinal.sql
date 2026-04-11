DECLARE @id_usuario INT;

DECLARE cur_final CURSOR FAST_FORWARD FOR
SELECT TOP 200 u.id_usuario
FROM usuarios u
WHERE u.activo = 1
  AND EXISTS (
      SELECT 1
      FROM perfil_usuario pu
      WHERE pu.id_usuario = u.id_usuario
  )
ORDER BY u.id_usuario;

OPEN cur_final;
FETCH NEXT FROM cur_final INTO @id_usuario;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC sp_crear_exam_final @id_usuario = @id_usuario;
    END TRY
    BEGIN CATCH
    END CATCH;

    FETCH NEXT FROM cur_final INTO @id_usuario;
END

CLOSE cur_final;
DEALLOCATE cur_final;