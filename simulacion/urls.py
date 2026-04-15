from django.urls import path
from . import views

urlpatterns = [
    path('', views.login_view, name='login'),
    path('signup/', views.signup_view, name='signup'),
    path('dashboard/', views.dashboard_view, name='dashboard'),
    path('examen/', views.examen_view, name='examen'),
    path('logout/', views.logout_view, name='logout'),

    # Simuladores
    path('simulador/practica/',  views.simulador_practica_view, name='simulador_practica'),
    path('simulador/final/',     views.simulador_final_view,    name='simulador_final'),
    path('simulador/responder/', views.responder_pregunta_view, name='responder_pregunta'),
    path('simulador/expirar/',   views.expirar_pregunta_view,   name='expirar_pregunta'),
    path('simulador/calificar/', views.calificar_examen_view,   name='calificar_examen'),

    # Revisión interna de imágenes
    path('IMAGENESSECRET/', views.imagenes_secret_view, name='imagenes_secret'),
]
