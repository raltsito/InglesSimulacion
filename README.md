# Antigravity — Simulación Inglés (Django)

Plataforma de simulacro de examen de inglés construida con Django.

## Estructura del proyecto

```
/
├── config/                     # Configuración Django (settings, urls, wsgi)
├── simulacion/                 # App principal
│   ├── templates/simulacion/   # Templates HTML
│   │   ├── login.html
│   │   ├── dashboard.html
│   │   └── examen_ingles.html
│   ├── views.py
│   └── urls.py
├── static/
│   └── images/
│       └── hinata.png
├── manage.py
└── README.md
```

## Levantar el proyecto

### 1. Instalar dependencias (solo la primera vez)

```bash
pip install django
```

### 2. Aplicar migraciones (solo la primera vez)

```bash
python manage.py migrate
```

### 3. Crear usuario de acceso (solo la primera vez)

```bash
python manage.py createsuperuser
```

O usar el usuario de prueba ya creado: **admin / admin123**

### 4. Correr el servidor

```bash
python manage.py runserver
```

Abre [http://localhost:8000](http://localhost:8000) en tu navegador.

## URLs

| URL | Vista |
|---|---|
| `/` | Login |
| `/dashboard/` | Dashboard (requiere login) |
| `/examen/` | Examen de inglés (requiere login) |
| `/logout/` | Cierra sesión |
| `/admin/` | Panel de administración Django |

## Flujo de navegación

```
/ (login)  →  /dashboard/  →  /examen/
    ↑               ↑___________↑
 /logout/              (volver)
```

## Escalar

- **Modelos**: agregar `models.py` en `simulacion/` para guardar resultados de exámenes.
- **API REST**: instalar `djangorestframework` y exponer endpoints.
- **Frontend moderno**: mantener Django como backend API y migrar el frontend a React/Vue.
