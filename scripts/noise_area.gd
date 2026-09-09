extends Area2D
class_name NoiseArea

signal noise_emitted(location: Vector2)

@export var radius: float = 160.0
@export var duration: float = 1.2

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_rect: ColorRect = $VisualRect

func _ready() -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius

	_emit_noise_to_patrols()

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_temporary_notification"):
		hud.show_temporary_notification("RUIDO DETECTADO", 1.5)

	get_tree().create_timer(duration).timeout.connect(queue_free)

func _emit_noise_to_patrols() -> void:
	noise_emitted.emit(global_position)
	var patrols = get_tree().get_nodes_in_group("enemies")
	for patrol in patrols:
		if patrol.has_method("on_noise_heard"):
			var dist = global_position.distance_to(patrol.global_position)
			if dist <= radius * 1.5:
				patrol.on_noise_heard(global_position)
