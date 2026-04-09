from django.urls import path
from . import views

urlpatterns = [
    path('', views.login_view, name='login'),
    path('dashboard/', views.dashboard_view, name='dashboard'),
    path('examen/', views.examen_view, name='examen'),
    path('logout/', views.logout_view, name='logout'),
]
