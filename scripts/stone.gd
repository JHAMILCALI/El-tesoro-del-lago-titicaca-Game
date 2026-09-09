extends Node2D
class_name Stone

@export var speed: float = 350.0
@export var travel_distance: float = 180.0

var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var noise_area_scene: PackedScene = preload("res://scenes/objects/NoiseArea.tscn")

func setup(launch_direction: Vector2) -> void:
	direction = launch_direction.normalized() if launch_direction != Vector2.ZERO else Vector2.RIGHT
	rotation = direction.angle()

func _process(delta: float) -> void:
	var move_step = speed * delta
	position += direction * move_step
	distance_traveled += move_step

	if distance_traveled >= travel_distance:
		_land()

func _land() -> void:
	if noise_area_scene:
		var noise_area = noise_area_scene.instantiate()
		noise_area.global_position = global_position
		get_parent().add_child(noise_area)
	queue_free()
