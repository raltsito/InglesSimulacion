from django.db import models


class Imagenes(models.Model):
    id_imagen = models.AutoField(primary_key=True)
    url_imagen = models.CharField(max_length=255)
    descripcion = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'imagenes'


class Usuarios(models.Model):
    id_usuario = models.AutoField(primary_key=True)
    matricula = models.CharField(unique=True, max_length=20)
    nombre = models.CharField(max_length=80)
    paterno = models.CharField(max_length=80)
    materno = models.CharField(max_length=80, blank=True, null=True)
    correo = models.CharField(unique=True, max_length=120)
    password_hash = models.CharField(max_length=255)
    intentos_practica = models.IntegerField()
    intentos_final = models.IntegerField()
    activo = models.BooleanField()

    class Meta:
        managed = False
        db_table = 'usuarios'


class PerfilUsuario(models.Model):
    id_usuario = models.IntegerField(primary_key=True)
    perfil = models.CharField(max_length=20, blank=True, null=True)
    prob_acierto = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'perfil_usuario'


class Preguntas(models.Model):
    id_pregunta = models.AutoField(primary_key=True)
    enunciado = models.CharField(max_length=500)
    opcion_a = models.CharField(max_length=255)
    opcion_b = models.CharField(max_length=255)
    opcion_c = models.CharField(max_length=255)
    opcion_d = models.CharField(max_length=255)
    respuesta_correcta = models.CharField(max_length=1)
    nivel = models.CharField(max_length=20)
    tipo_examen = models.CharField(max_length=20)
    materia = models.CharField(max_length=50)
    activa = models.BooleanField()
    id_imagen = models.ForeignKey(Imagenes, models.DO_NOTHING, db_column='id_imagen', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'preguntas'


class Examenes(models.Model):
    id_examen = models.AutoField(primary_key=True)
    id_usuario = models.ForeignKey(Usuarios, models.DO_NOTHING, db_column='id_usuario')
    tipo = models.CharField(max_length=20)
    fecha_inicio = models.DateTimeField()
    fecha_fin = models.DateTimeField(blank=True, null=True)
    tiempo_pregunta_seg = models.IntegerField()
    total_preguntas = models.IntegerField()
    aciertos = models.IntegerField()
    errores = models.IntegerField()
    porcentaje = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    aprobado = models.BooleanField()
    nivel_obtenido = models.CharField(max_length=20, blank=True, null=True)
    estado = models.CharField(max_length=20)

    class Meta:
        managed = False
        db_table = 'examenes'


class ExamenPreguntas(models.Model):
    id_exam_pregunta = models.AutoField(primary_key=True)
    id_examen = models.ForeignKey(Examenes, models.DO_NOTHING, db_column='id_examen')
    id_pregunta = models.ForeignKey(Preguntas, models.DO_NOTHING, db_column='id_pregunta')
    numero_orden = models.IntegerField()
    respondida = models.IntegerField()
    tiempo_consumido_seg = models.IntegerField()
    expiro_tiempo = models.BooleanField()

    class Meta:
        managed = False
        db_table = 'examen_preguntas'
        unique_together = (('id_examen', 'numero_orden'), ('id_examen', 'id_pregunta'),)


class RespuestaUsuario(models.Model):
    id_respuesta = models.AutoField(primary_key=True)
    id_exam_pregunta = models.OneToOneField(ExamenPreguntas, models.DO_NOTHING, db_column='id_exam_pregunta')
    respuesta_selec = models.CharField(max_length=1, blank=True, null=True)
    es_correcta = models.BooleanField()
    tiempo_respuesta_seg = models.IntegerField()
    expiro_tiempo = models.BooleanField()

    class Meta:
        managed = False
        db_table = 'respuesta_usuario'


class HistorialEstudiante(models.Model):
    id_historial = models.AutoField(primary_key=True)
    id_usuario = models.ForeignKey(Usuarios, models.DO_NOTHING, db_column='id_usuario')
    id_examen = models.OneToOneField(Examenes, models.DO_NOTHING, db_column='id_examen')
    tipo_examen = models.CharField(max_length=20)
    fecha = models.DateTimeField()
    puntaje = models.DecimalField(max_digits=5, decimal_places=2)
    porcentaje = models.DecimalField(max_digits=5, decimal_places=2)
    aprobado = models.BooleanField()
    nivel_obtenido = models.CharField(max_length=20, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'historial_estudiante'
