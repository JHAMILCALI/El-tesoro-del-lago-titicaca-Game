extends Area2D
class_name CurrentZone

@export var force: Vector2 = Vector2(90, 0)

func _ready() -> void:
	var visual := get_node_or_null("Visual") as Sprite2D
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if visual and collision and collision.shape is RectangleShape2D:
		visual.call("configure", force, (collision.shape as RectangleShape2D).size)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is BoatPrototype:
			body.apply_current(force)

func _on_body_entered(body: Node2D) -> void:
	if body is BoatPrototype:
		body.apply_current(force)
		var level = get_tree().get_first_node_in_group("lake_level")
		if level and level.has_method("show_notification"):
			level.show_notification("CORRIENTE: la barca se desvía", 1.5)

func _on_body_exited(body: Node2D) -> void:
	if body is BoatPrototype:
		body.apply_current(Vector2.ZERO)
