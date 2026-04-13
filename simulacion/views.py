import json
import functools
from django.shortcuts import render, redirect
from django.http import JsonResponse
from django.db import connection
from django.contrib.auth.hashers import make_password, check_password
from .models import Usuarios, Examenes, ExamenPreguntas


# ── Custom session auth ──────────────────────────────────────────────────────

def login_required(view_func):
    @functools.wraps(view_func)
    def wrapper(request, *args, **kwargs):
        if 'id_usuario' not in request.session:
            return redirect('login')
        return view_func(request, *args, **kwargs)
    return wrapper


# ── Auth views ───────────────────────────────────────────────────────────────

def login_view(request):
    if 'id_usuario' in request.session:
        return redirect('dashboard')

    error = None
    if request.method == 'POST':
        username = request.POST.get('username', '').strip()
        password = request.POST.get('password', '')

        usuario = (
            Usuarios.objects.filter(correo=username, activo=True).first()
            or Usuarios.objects.filter(matricula=username, activo=True).first()
        )

        if usuario and check_password(password, usuario.password_hash):
            request.session['id_usuario'] = usuario.id_usuario
            request.session['nombre']     = usuario.nombre
            request.session['paterno']    = usuario.paterno
            request.session['matricula']  = usuario.matricula
            return redirect('dashboard')

        error = 'Usuario o contraseña incorrectos.'

    return render(request, 'simulacion/login.html', {'error': error})


def signup_view(request):
    if 'id_usuario' in request.session:
        return redirect('dashboard')

    error = None
    if request.method == 'POST':
        nombre    = request.POST.get('nombre', '').strip()
        paterno   = request.POST.get('paterno', '').strip()
        materno   = request.POST.get('materno', '').strip() or None
        matricula = request.POST.get('matricula', '').strip()
        correo    = request.POST.get('correo', '').strip()
        password  = request.POST.get('password', '')
        password2 = request.POST.get('password2', '')

        if not all([nombre, paterno, matricula, correo, password]):
            error = 'Todos los campos obligatorios deben estar completos.'
        elif password != password2:
            error = 'Las contraseñas no coinciden.'
        elif len(password) < 6:
            error = 'La contraseña debe tener al menos 6 caracteres.'
        elif Usuarios.objects.filter(correo=correo).exists():
            error = 'El correo ya está registrado.'
        elif Usuarios.objects.filter(matricula=matricula).exists():
            error = 'La matrícula ya está registrada.'
        else:
            Usuarios.objects.create(
                nombre=nombre,
                paterno=paterno,
                materno=materno,
                matricula=matricula,
                correo=correo,
                password_hash=make_password(password),
                intentos_practica=0,
                intentos_final=0,
                activo=True,
            )
            return redirect('login')

    return render(request, 'simulacion/signup.html', {'error': error})


def logout_view(request):
    request.session.flush()
    return redirect('login')


# ── Protected views ──────────────────────────────────────────────────────────

@login_required
def dashboard_view(request):
    return render(request, 'simulacion/dashboard.html')


@login_required
def examen_view(request):
    return render(request, 'simulacion/examen_ingles.html')


# ── Simulador de práctica ────────────────────────────────────────────────────

@login_required
def simulador_practica_view(request):
    id_usuario = request.session['id_usuario']

    # Reutilizar examen en curso si existe
    examen_en_curso = Examenes.objects.filter(
        id_usuario=id_usuario, tipo='Practica', estado='EnCurso'
    ).first()

    if examen_en_curso:
        id_examen = examen_en_curso.id_examen
    else:
        try:
            with connection.cursor() as cursor:
                cursor.execute(
                    "EXEC sp_crear_exam_practica @id_usuario=%s", [id_usuario]
                )
                row = cursor.fetchone()
                id_examen = row[0]
        except Exception as e:
            return render(request, 'simulacion/simulador_practica.html', {
                'error': str(e)
            })

    # Cargar preguntas no respondidas del examen
    exam_preguntas = (
        ExamenPreguntas.objects
        .filter(id_examen=id_examen, respondida=0)
        .select_related('id_pregunta', 'id_pregunta__id_imagen')
        .order_by('numero_orden')
    )

    preguntas_data = []
    for ep in exam_preguntas:
        p = ep.id_pregunta
        preguntas_data.append({
            'id_exam_pregunta':   ep.id_exam_pregunta,
            'numero_orden':       ep.numero_orden,
            'enunciado':          p.enunciado,
            'opcion_a':           p.opcion_a,
            'opcion_b':           p.opcion_b,
            'opcion_c':           p.opcion_c,
            'opcion_d':           p.opcion_d,
            'respuesta_correcta': p.respuesta_correcta,
            'nivel':              p.nivel,
            'materia':            p.materia,
            'imagen_url':         p.id_imagen.url_imagen if p.id_imagen else None,
        })

    return render(request, 'simulacion/simulador_practica.html', {
        'id_examen':      id_examen,
        'preguntas_json': json.dumps(preguntas_data, ensure_ascii=False),
        'tiempo_max':     60,
        'nombre':         request.session.get('nombre', ''),
    })


# ── Simulador final ──────────────────────────────────────────────────────────

@login_required
def simulador_final_view(request):
    id_usuario = request.session['id_usuario']

    examen_en_curso = Examenes.objects.filter(
        id_usuario=id_usuario, tipo='Final', estado='EnCurso'
    ).first()

    if examen_en_curso:
        id_examen = examen_en_curso.id_examen
    else:
        try:
            with connection.cursor() as cursor:
                cursor.execute(
                    "EXEC sp_crear_exam_final @id_usuario=%s", [id_usuario]
                )
                row = cursor.fetchone()
                id_examen = row[0]
        except Exception as e:
            return render(request, 'simulacion/simulador_final.html', {
                'error': str(e)
            })

    exam_preguntas = (
        ExamenPreguntas.objects
        .filter(id_examen=id_examen, respondida=0)
        .select_related('id_pregunta', 'id_pregunta__id_imagen')
        .order_by('numero_orden')
    )

    preguntas_data = []
    for ep in exam_preguntas:
        p = ep.id_pregunta
        preguntas_data.append({
            'id_exam_pregunta': ep.id_exam_pregunta,
            'numero_orden':     ep.numero_orden,
            'enunciado':        p.enunciado,
            'opcion_a':         p.opcion_a,
            'opcion_b':         p.opcion_b,
            'opcion_c':         p.opcion_c,
            'opcion_d':         p.opcion_d,
            'nivel':            p.nivel,
            'materia':          p.materia,
            'imagen_url':       p.id_imagen.url_imagen if p.id_imagen else None,
        })

    intentos_usados = Examenes.objects.filter(
        id_usuario=id_usuario, tipo='Final'
    ).count()

    return render(request, 'simulacion/simulador_final.html', {
        'id_examen':       id_examen,
        'preguntas_json':  json.dumps(preguntas_data, ensure_ascii=False),
        'tiempo_max':      60,
        'intentos_usados': intentos_usados,
        'nombre':          request.session.get('nombre', ''),
    })


@login_required
def responder_pregunta_view(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    data = json.loads(request.body)
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "EXEC sp_registrar_respuestas "
                "@id_exam_pregunta=%s, @respuesta_seleccionada=%s, @tiempo_respuesta_seg=%s",
                [data['id_exam_pregunta'], data['respuesta'], data['tiempo']]
            )
        return JsonResponse({'ok': True})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)


@login_required
def expirar_pregunta_view(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    data = json.loads(request.body)
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "EXEC sp_expirar_pregunta @id_exam_pregunta=%s",
                [data['id_exam_pregunta']]
            )
        return JsonResponse({'ok': True})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)


@login_required
def calificar_examen_view(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    data = json.loads(request.body)
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "EXEC sp_calificar_examen @id_examen=%s", [data['id_examen']]
            )
            row  = cursor.fetchone()
            cols = [d[0] for d in cursor.description]
            resultado = dict(zip(cols, row))
        # Convertir Decimal a float para JSON
        for k, v in resultado.items():
            if hasattr(v, '__float__'):
                resultado[k] = float(v)
        return JsonResponse(resultado)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)
