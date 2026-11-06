extends CharacterBody2D

signal defeated(enemy: Node2D, points: float)

var enemy_type := "Entrega"
var hp := 1
var speed := 55.0
var damage := 10.0
var points := 8.0
var target: Node2D
var wander_direction := Vector2.RIGHT
var wander_timer := 0.0
var attack_timer := 0.0
var boss := false
var _hit_flash := 0.0

func setup(kind: String, player: Node2D, is_boss: bool = false) -> void:
	enemy_type = kind
	target = player
	boss = is_boss
	match kind:
		"Notificación":
			hp = 1
			speed = 38.0
			points = 7.0
		"Desvelo":
			hp = 2
			speed = 105.0
			points = 9.0
		"Parcial":
			hp = 5
			speed = 30.0
			points = 16.0
		"Agotamiento":
			hp = 28
			speed = 72.0
			damage = 16.0
			points = 0.0
	if boss:
		hp = 28
		speed = 72.0
		damage = 16.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0 if not boss else 29.0
	shape.shape = circle
	add_child(shape)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta)
	var direction := Vector2.ZERO
	if enemy_type == "Entrega" or enemy_type == "Notificación":
		wander_timer -= delta
		if wander_timer <= 0.0:
			wander_timer = randf_range(0.7, 1.8)
			wander_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
		direction = wander_direction
		if global_position.distance_to(target.global_position) < 125.0:
			direction = global_position.direction_to(target.global_position) * 0.45 + wander_direction * 0.55
	elif enemy_type == "Agotamiento":
		direction = global_position.direction_to(target.global_position)
	else:
		direction = global_position.direction_to(target.global_position)
	velocity = direction.normalized() * speed
	move_and_slide()
	position.x = clampf(position.x, 35.0, 925.0)
	position.y = clampf(position.y, 105.0, 495.0)

	if global_position.distance_to(target.global_position) < (38.0 if boss else 27.0) and attack_timer <= 0.0:
		attack_timer = 0.9 if boss else 1.2
		target.take_hit(damage)
	queue_redraw()

func take_damage(amount: float) -> void:
	hp -= int(ceil(amount))
	_hit_flash = 0.12
	if hp <= 0:
		defeated.emit(self, points)
		queue_free()

func _draw() -> void:
	var c := Color(0.78, 0.38, 0.28)
	match enemy_type:
		"Notificación": c = Color(0.34, 0.68, 0.92)
		"Desvelo": c = Color(0.46, 0.38, 0.68)
		"Parcial": c = Color(0.85, 0.72, 0.34)
		"Agotamiento": c = Color(0.55, 0.12, 0.18)
	if _hit_flash > 0.0:
		c = Color.WHITE
	var radius := 29.0 if boss else 15.0
	draw_circle(Vector2.ZERO, radius, c)
	draw_rect(Rect2(-radius * 0.55, -radius * 0.35, radius * 1.1, radius * 0.7), Color(0.95, 0.9, 0.78))
	draw_circle(Vector2(-radius * 0.22, -2), 2.0, Color(0.12, 0.12, 0.12))
	draw_circle(Vector2(radius * 0.22, -2), 2.0, Color(0.12, 0.12, 0.12))
	draw_rect(Rect2(-radius, -radius - 9, radius * 2, 4), Color(0.18, 0.12, 0.12))
	draw_rect(Rect2(-radius, -radius - 9, radius * 2 * float(hp) / (28.0 if boss else (5.0 if enemy_type == "Parcial" else (2.0 if enemy_type == "Desvelo" else 1.0))), 4), Color(0.85, 0.2, 0.2))
