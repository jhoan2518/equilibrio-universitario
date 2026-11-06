extends Area2D

var direction := Vector2.RIGHT
var speed := 430.0
var damage := 1.0
var life := 1.2

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color(0.55, 0.85, 1.0))
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
