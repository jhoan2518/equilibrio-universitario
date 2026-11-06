extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const PickupScript = preload("res://scripts/pickup.gd")

const ROOMS := ["Pasillo central", "Biblioteca / Salón", "Tu cuarto", "Cafetería / Parque"]
const ADVICE := [
	"Semana 1: organiza tus tareas en pasos pequeños. Avanzar poco a poco también cuenta.",
	"Semana 2: dormir y hacer pausas ayuda a recuperar la atención.",
	"Semana 3: hablar con alguien de confianza puede ayudarte a no cargar todo a solas.",
	"Semana 4: pedir apoyo y planear tu tiempo también son parte del aprendizaje."
]

var player: CharacterBody2D
var enemies: Array[Node2D] = []
var room := "Pasillo central"
var spawn_timer := 0.0
var pickup_timer := 0.0
var week_elapsed := 0.0
var boss_spawned := false
var game_finished := false
var paused_for_message := false
var message_label: Label
var hud_labels := {}
var bars := {}
var dark_overlay: ColorRect
var room_hint := ""

func _ready() -> void:
	randomize()
	_setup_input()
	GameState.reset()
	GameState.exhausted.connect(_on_exhausted)
	GameState.resources_changed.connect(_update_hud)
	_build_ui()
	player = PlayerScript.new()
	player.name = "Player"
	player.position = Vector2(480, 300)
	player.attack_requested.connect(_on_player_attack)
	player.interact_requested.connect(_on_interact)
	add_child(player)
	_update_hud()
	queue_redraw()

func _setup_input() -> void:
	_add_key("move_up", KEY_W)
	_add_key("move_up", KEY_UP)
	_add_key("move_down", KEY_S)
	_add_key("move_down", KEY_DOWN)
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_key("attack", KEY_SPACE)
	_add_key("interact", KEY_E)

func _add_key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(14, 12)
	panel.size = Vector2(320, 132)
	layer.add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var title := Label.new()
	title.text = "EQUILIBRIO UNIVERSITARIO"
	title.add_theme_font_size_override("font_size", 17)
	v.add_child(title)
	for key in ["Energía", "Estudio", "Descanso", "Social"]:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = key
		label.custom_minimum_size.x = 78
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(185, 15)
		bar.max_value = 100
		bar.show_percentage = false
		row.add_child(bar)
		var value := Label.new()
		value.custom_minimum_size.x = 36
		row.add_child(value)
		v.add_child(row)
		bars[key] = bar
		hud_labels[key] = value
	var room_label := Label.new()
	room_label.name = "RoomLabel"
	room_label.position = Vector2(730, 16)
	room_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(room_label)
	hud_labels["room"] = room_label
	var help := Label.new()
	help.text = "WASD/Flechas: mover   ESPACIO: lanzar idea   E: usar puerta"
	help.position = Vector2(20, 514)
	help.add_theme_font_size_override("font_size", 14)
	layer.add_child(help)
	message_label = Label.new()
	message_label.position = Vector2(260, 190)
	message_label.size = Vector2(440, 150)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.visible = false
	layer.add_child(message_label)
	dark_overlay = ColorRect.new()
	dark_overlay.position = Vector2.ZERO
	dark_overlay.size = Vector2(960, 540)
	dark_overlay.color = Color(0.02, 0.025, 0.06, 0.0)
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dark_overlay)

func _unhandled_input(event: InputEvent) -> void:
	if paused_for_message and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		_close_message()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if game_finished or paused_for_message:
		return
	week_elapsed += delta
	var fighting := not enemies.is_empty()
	GameState.tick(delta, room, fighting)
	spawn_timer -= delta
	pickup_timer -= delta
	if spawn_timer <= 0.0 and not GameState.boss_active:
		_spawn_for_week()
		spawn_timer = maxf(1.4, 4.2 - GameState.week * 0.45)
	if pickup_timer <= 0.0:
		_spawn_pickup()
		pickup_timer = randf_range(9.0, 14.0)
	_check_week_progress()
	_update_hud()
	queue_redraw()

func _draw() -> void:
	var floor_color := Color(0.18, 0.22, 0.28)
	match room:
		"Biblioteca / Salón": floor_color = Color(0.25, 0.22, 0.17)
		"Tu cuarto": floor_color = Color(0.18, 0.24, 0.30)
		"Cafetería / Parque": floor_color = Color(0.16, 0.28, 0.22)
	draw_rect(Rect2(0, 0, 960, 540), floor_color)
	for x in range(0, 960, 48):
		draw_line(Vector2(x, 88), Vector2(x, 540), Color(1, 1, 1, 0.035), 1)
	for y in range(88, 540, 48):
		draw_line(Vector2(0, y), Vector2(960, y), Color(1, 1, 1, 0.035), 1)
	draw_rect(Rect2(0, 88, 960, 4), Color(0.72, 0.75, 0.8, 0.5))
	_draw_room_decor()
	_draw_doors()

func _draw_room_decor() -> void:
	match room:
		"Biblioteca / Salón":
			draw_rect(Rect2(60, 130, 120, 28), Color(0.45, 0.29, 0.16))
			draw_rect(Rect2(760, 130, 140, 28), Color(0.45, 0.29, 0.16))
			draw_string(ThemeDB.fallback_font, Vector2(65, 124), "ESTUDIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.9, 0.65))
		"Tu cuarto":
			draw_rect(Rect2(360, 160, 240, 90), Color(0.36, 0.43, 0.55))
			draw_rect(Rect2(375, 170, 210, 55), Color(0.72, 0.77, 0.84))
			draw_string(ThemeDB.fallback_font, Vector2(420, 145), "ZONA DE DESCANSO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.9, 1))
		"Cafetería / Parque":
			draw_rect(Rect2(330, 220, 300, 70), Color(0.48, 0.32, 0.19))
			draw_circle(Vector2(250, 300), 30, Color(0.22, 0.48, 0.28))
			draw_circle(Vector2(720, 330), 36, Color(0.22, 0.48, 0.28))
			draw_string(ThemeDB.fallback_font, Vector2(385, 205), "CONEXIÓN Y APOYO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.85, 1, 0.85))
		_:
			draw_rect(Rect2(410, 210, 140, 90), Color(0.3, 0.34, 0.4))
			draw_string(ThemeDB.fallback_font, Vector2(420, 200), "PASILLO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.85, 0.88, 0.95))

func _draw_doors() -> void:
	var doors := _get_doors()
	for d in doors:
		draw_rect(Rect2(d["pos"] - Vector2(24, 24), Vector2(48, 48)), Color(0.86, 0.78, 0.48, 0.9))
		draw_string(ThemeDB.fallback_font, d["pos"] + Vector2(-34, 43), d["label"], HORIZONTAL_ALIGNMENT_LEFT, 90, 12, Color.WHITE)

func _get_doors() -> Array:
	match room:
		"Pasillo central":
			return [
				{"pos": Vector2(480, 125), "to": "Biblioteca / Salón", "label": "Biblioteca"},
				{"pos": Vector2(125, 300), "to": "Tu cuarto", "label": "Cuarto"},
				{"pos": Vector2(835, 300), "to": "Cafetería / Parque", "label": "Cafetería"}
			]
		"Biblioteca / Salón":
			return [{"pos": Vector2(480, 125), "to": "Pasillo central", "label": "Pasillo"}]
		"Tu cuarto":
			return [{"pos": Vector2(835, 300), "to": "Pasillo central", "label": "Pasillo"}]
		_:
			return [{"pos": Vector2(125, 300), "to": "Pasillo central", "label": "Pasillo"}]

func _on_interact() -> void:
	if paused_for_message or game_finished:
		if paused_for_message:
			_close_message()
		return
	var nearest: Dictionary = {}
	var best := 58.0
	for d in _get_doors():
		var dist: float = player.global_position.distance_to(d["pos"])
		if dist < best:
			best = dist
			nearest = d
	if not nearest.is_empty():
		_change_room(nearest["to"])

func _change_room(next_room: String) -> void:
	room = next_room
	match room:
		"Biblioteca / Salón": player.position = Vector2(480, 455)
		"Tu cuarto": player.position = Vector2(800, 300)
		"Cafetería / Parque": player.position = Vector2(160, 300)
		_: player.position = Vector2(480, 170)
	spawn_timer = 1.5
	queue_redraw()
	_update_hud()

func _on_player_attack(origin: Vector2, direction: Vector2) -> void:
	if paused_for_message or game_finished:
		return
	var p := ProjectileScript.new()
	p.global_position = origin
	p.direction = direction
	p.damage = 2.0 if GameState.is_concentrated else 1.0
	add_child(p)

func _spawn_for_week() -> void:
	if room == "Tu cuarto" or room == "Cafetería / Parque":
		return
	var cap := 2 + GameState.week
	if room == "Pasillo central":
		cap = 1
	if enemies.size() >= cap:
		return
	var kind := "Entrega"
	var roll := randf()
	if GameState.week >= 2 and roll > 0.55:
		kind = "Notificación"
	if GameState.week >= 3 and GameState.rest < 42.0 and roll > 0.35:
		kind = "Desvelo"
	elif GameState.week >= 3 and roll > 0.72:
		kind = "Parcial"
	var e := EnemyScript.new()
	e.setup(kind, player)
	e.position = _random_spawn_position()
	e.defeated.connect(_on_enemy_defeated)
	add_child(e)
	enemies.append(e)

func _random_spawn_position() -> Vector2:
	var side := randi_range(0, 3)
	match side:
		0: return Vector2(randf_range(70, 890), 115)
		1: return Vector2(randf_range(70, 890), 485)
		2: return Vector2(45, randf_range(140, 470))
		_: return Vector2(915, randf_range(140, 470))

func _on_enemy_defeated(enemy: Node2D, points: float) -> void:
	enemies.erase(enemy)
	GameState.al_derrotar_enemigo(points)
	if randf() < 0.18:
		_spawn_pickup_at(enemy.global_position)

func _spawn_pickup() -> void:
	if room == "Biblioteca / Salón" and randf() < 0.45:
		return
	_spawn_pickup_at(Vector2(randf_range(100, 860), randf_range(150, 465)))

func _spawn_pickup_at(pos: Vector2) -> void:
	if get_tree().get_nodes_in_group("pickups").size() > 7:
		return
	var kinds := ["energia", "descanso", "social"]
	var kind: String = kinds[randi_range(0, kinds.size() - 1)]
	if GameState.social < 25.0 and kind == "energia" and randf() < 0.6:
		kind = "descanso"
	var item := PickupScript.new()
	item.setup(kind, 22.0)
	item.position = pos
	item.add_to_group("pickups")
	add_child(item)

func _check_week_progress() -> void:
	if GameState.week > 4 or GameState.boss_active:
		return
	var goals := [0.0, 62.0, 72.0, 82.0, 92.0]
	if GameState.study >= goals[GameState.week]:
		_show_message("SEMANA %d COMPLETADA\n%s\n\nPulsa E para continuar." % [GameState.week, ADVICE[GameState.week - 1]])
		GameState.advance_week()
		week_elapsed = 0.0
		spawn_timer = 3.0
		if GameState.week == 5:
			_show_message("EXAMEN FINAL\nEl Agotamiento se acerca. Mantén tus recursos equilibrados.\n\nPulsa E para enfrentarlo.")
			GameState.boss_active = true

func _spawn_boss() -> void:
	if boss_spawned:
		return
	boss_spawned = true
	_change_room("Biblioteca / Salón")
	var boss := EnemyScript.new()
	boss.setup("Agotamiento", player, true)
	boss.position = Vector2(760, 270)
	boss.defeated.connect(_on_boss_defeated)
	add_child(boss)
	enemies.append(boss)

func _on_boss_defeated(_enemy: Node2D, _points: float) -> void:
	enemies.clear()
	game_finished = true
	player.game_over = true
	_show_message("¡SEMESTRE SUPERADO!\n\nRendir bien no significa darlo todo siempre. Estudiar, descansar y conectar con otras personas también hacen parte del éxito.\n\nEste juego es educativo y no reemplaza la orientación profesional. Si necesitas apoyo emocional en Colombia, consulta los canales oficiales de salud de tu municipio o la Línea 106 donde esté disponible.\n\nPulsa E para volver a jugar.")

func _on_exhausted() -> void:
	if game_finished:
		return
	if not GameState.boss_active:
		GameState.boss_active = true
		_show_message("ALERTA: AGOTAMIENTO\nUno de tus recursos llegó a cero. El jefe aparece antes de tiempo.\n\nRecupera el equilibrio y prepárate. Pulsa E.")
		_spawn_boss()
	else:
		game_finished = true
		player.game_over = true
		_show_message("SEMESTRE INTERRUMPIDO\nTu energía o tus recursos llegaron a cero. No es un fracaso: identifica qué necesitas recuperar y vuelve a intentarlo.\n\nPulsa E para volver a jugar.")

func _show_message(text_value: String) -> void:
	paused_for_message = true
	message_label.text = text_value
	message_label.visible = true
	if player:
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)

func _close_message() -> void:
	message_label.visible = false
	paused_for_message = false
	if player and not game_finished:
		player.set_physics_process(true)
	if GameState.boss_active and not boss_spawned and not game_finished:
		_spawn_boss()
	if game_finished:
		_restart()

func _restart() -> void:
	get_tree().reload_current_scene()

func _update_hud() -> void:
	if not is_instance_valid(message_label) and bars.is_empty():
		return
	var values := {"Energía": GameState.energy, "Estudio": GameState.study, "Descanso": GameState.rest, "Social": GameState.social}
	for key in values:
		if bars.has(key):
			bars[key].value = values[key]
			hud_labels[key].text = str(int(values[key]))
	if hud_labels.has("room"):
		hud_labels["room"].text = "%s  |  Semana %d/4" % [room, mini(GameState.week, 4)]
	if is_instance_valid(dark_overlay):
		dark_overlay.color.a = 0.16 if GameState.rest < 25.0 else 0.0
