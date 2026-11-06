extends Area2D

var pickup_type := "descanso"
var amount := 22.0
var bob := 0.0

func setup(kind: String, value: float = 22.0) -> void:
	pickup_type = kind
	amount = value

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	bob += delta * 3.0
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		GameState.recuperar(pickup_type, amount)
		queue_free()

func _draw() -> void:
	var c := Color(0.45, 0.78, 0.95)
	if pickup_type == "social":
		c = Color(0.95, 0.52, 0.67)
	elif pickup_type == "energia":
		c = Color(0.5, 0.85, 0.48)
	draw_circle(Vector2(0, sin(bob) * 3.0), 11.0, c)
	draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
