extends CharacterBody2D

signal attack_requested(origin: Vector2, direction: Vector2)
signal interact_requested

@export var base_speed := 190.0
var facing := Vector2.DOWN
var attack_cooldown := 0.0
var invulnerability := 0.0
var game_over := false

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	shape.shape = circle
	add_child(shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if game_over:
		velocity = Vector2.ZERO
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	invulnerability = maxf(0.0, invulnerability - delta)

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.length() > 0.1:
		facing = input.normalized()
	var speed := base_speed
	if GameState.rest < 25.0:
		speed *= 0.68
	velocity = input * speed
	move_and_slide()
	position.x = clampf(position.x, 38.0, 922.0)
	position.y = clampf(position.y, 100.0, 500.0)

	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
		attack_cooldown = 0.38
		attack_requested.emit(global_position + facing * 18.0, facing)
		GameState.al_atacar()
	if Input.is_action_just_pressed("interact"):
		interact_requested.emit()
	queue_redraw()

func take_hit(amount: float = 10.0) -> void:
	if invulnerability > 0.0 or game_over:
		return
	invulnerability = 0.8
	GameState.recibir_golpe(amount)

func _draw() -> void:
	var tint := Color(0.95, 0.82, 0.57)
	if invulnerability > 0.0 and int(Time.get_ticks_msec() / 100) % 2 == 0:
		tint = Color(1, 1, 1, 0.35)
	draw_circle(Vector2.ZERO, 13.0, tint)
	draw_rect(Rect2(-9, -3, 18, 13), Color(0.18, 0.38, 0.72))
	draw_circle(Vector2(0, -4), 8.0, Color(0.88, 0.68, 0.48))
	draw_rect(Rect2(-8, -15, 16, 5), Color(0.22, 0.16, 0.12))
	draw_circle(facing * 8.0 + Vector2(0, -4), 1.5, Color(0.08, 0.08, 0.08))
