# Equilibrio Universitario — prototipo Godot 4

## Cómo abrir
1. Descomprime `EquilibrioUniversitario_Godot.zip`.
2. Abre Godot 4.x.
3. Pulsa **Importar** y selecciona `project.godot`.
4. Ejecuta con F6/F5 (o el botón Play).

## Controles
- WASD o flechas: moverse.
- ESPACIO: lanzar una idea (proyectil).
- E: entrar por una puerta / continuar mensajes.

## Qué incluye este prototipo
- Cuatro salas conectadas: pasillo, biblioteca, cuarto y cafetería.
- Recursos: energía, estudio, descanso y social.
- Recuperación de descanso/social según la sala y objetos recogibles.
- Enemigos de semestre y proyectiles.
- Penalización por descanso bajo y daño adicional al estar concentrado.
- Progreso por semanas, mensajes educativos y jefe Agotamiento.

## Importante
Es una primera versión jugable con gráficos dibujados por código (sin sprites externos).
La Línea 106 se menciona únicamente como canal que puede existir según el territorio; antes de publicar el juego, verifica disponibilidad, horario y número con una fuente oficial local. El texto de cierre debe revisarse con la entidad de salud correspondiente.

## Integración con tu proyecto anterior
El prototipo es independiente para que puedas ejecutarlo sin romper tus escenas existentes.
Tu sistema anterior usaba `move_transition_player(direction, distance)` y transiciones de cámara con `camera_2d`; cuando compartas el proyecto `.zip` o las escenas/scripts actuales, se puede integrar esta lógica de recursos y salas conservando esas transiciones.
