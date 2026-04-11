# Base de datos - Simulador
Detalle de la base de datos para el Simulador de Ingles con scripts para generar datos de prueba.
## Estructura
```
scripts_simulador_ingles_BD/
├── 01_creacion_tablas.sql
├── 02_constraint_y_relaciones.sql
├── 03_stored_procedures.sql
├── 04_cargar_preguntas.sql
├── 05_perfiles_simulaciones/
│   └── (scripts para generar usuarios, exámenes y respuestas)
├── 06_dashboard_consultas/
│   └── (consultas para métricas del sistema)
```
## Requisitos
- SQL Server (Express o superior)
- SQL Server Management Studio (SSMS)

## Instalación BD
1. Crear base de datos
``` SQL
CREATE DATABASE SimuladorIngles;
GO
USE SimuladorIngles;
```
2. Ejecutar scripts en este orden
```
01_creacion_tablas.sql
02_constraint_y_relaciones.sql
03_stored_procedures.sql
04_cargar_preguntas.sql
```
3. Generar datos de prueba
```
05_perfiles_simulaciones/*
```
4. Consultas de Dashboard
```
06_dashboard_consultas/*
```

## Lógica del Sistema
**Tipos de examen**
- **Práctica**: Cada reactivo vale 5 puntos. Un máximo de 5 pruebas por usuario.
- Final: Cada reactivo vale 2.5 puntos. Un máximo de 2 pruebas por usuario.

**Estados del examen**
- En curso
- Finalizado
- Cancelado

**Reglas**
- Un usuario **no puede tener más de un examen en curso**.
- Si un ecamen se interrumpe:
    - Se marca como Cancelado.
    - Se califica automáticamente.
    - Se registra un historial.
- Se evita duplicado en historial.

## Simulaciones de Usuario con Perfil de Usuario
Se generaron perfiles para establecer diferentes probabilidades de acierto y obtener resultados más variados.
- Bajo: 30%
- Medio: 58%
- Bueno: 78%
- MuyBueno: 92%

## Validaciones
``` SQL
SELECT COUNT(*) 
FROM examenes
WHERE estado = 'Finalizado'
AND porcentaje IS NULL;
```
Verifica que todos los exámenes fueron calificados.

``` SQL
SELECT COUNT(*) 
FROM examenes
WHERE estado = 'Finalizado'
AND porcentaje IS NULL;
```
Verifica consistencia de preguntas.

