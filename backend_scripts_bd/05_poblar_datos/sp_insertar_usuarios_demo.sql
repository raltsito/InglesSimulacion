USE [SimuladorIngles]
GO

/****** Object:  StoredProcedure [dbo].[sp_insertar_usuarios_demo]    Script Date: 15/4/2026 10:45:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[sp_insertar_usuarios_demo]
    @cantidad_usuarios INT = 1000,
    @solo_activos BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @cantidad_usuarios IS NULL OR @cantidad_usuarios <= 0
    BEGIN
        RAISERROR('La cantidad de usuarios debe ser mayor a 0.', 16, 1);
        RETURN;
    END;
    /*CTE**/
    ;WITH nums AS 
    (
        SELECT TOP (@cantidad_usuarios)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a
        CROSS JOIN sys.all_objects b /**Tabla del sistema*/
    )
    INSERT INTO dbo.usuarios
    (
        matricula,
        nombre,
        paterno,
        materno,
        correo,
        password_hash,
        intentos_practica,
        intentos_final,
        activo
    )
    SELECT
        CONCAT('DEMO', RIGHT(CONCAT('000000', n), 6)) AS matricula,
        CONCAT('Usuario', n) AS nombre,
        'Demo' AS paterno,
        CONCAT('Test', n) AS materno,
        CONCAT('demo', n, '@test.local') AS correo,
        CONVERT(varchar(255), HASHBYTES('SHA2_256', 'Demo123*'), 2),
        0 AS intentos_practica,
        0 AS intentos_final,
        CASE WHEN @solo_activos = 1 THEN 1 ELSE CASE WHEN n % 10 = 0 THEN 0 ELSE 1 END END AS activo
    FROM nums
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.usuarios u
        WHERE u.matricula = CONCAT('DEMO', RIGHT(CONCAT('000000', nums.n), 6))
           OR u.correo = CONCAT('demo', nums.n, '@test.local')
    );

    SELECT
        COUNT(*) AS total_usuarios_demo
    FROM dbo.usuarios
    WHERE matricula LIKE 'DEMO%';
END;
GO


