extends Node2D
class_name Stone

@export var speed: float = 380.0
@export var travel_distance: float = 180.0
@export var direct_hit_radius: float = 24.0

var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var noise_area_scene: PackedScene = preload("res://scenes/objects/NoiseArea.tscn")

func setup(launch_direction: Vector2, target_distance: float = 180.0) -> void:
	direction = launch_direction.normalized() if launch_direction != Vector2.ZERO else Vector2.RIGHT
	travel_distance = maxf(20.0, target_distance)
	rotation = direction.angle()

func _process(delta: float) -> void:
	var move_step = speed * delta
	position += direction * move_step
	distance_traveled += move_step
	if _try_direct_patrol_hit():
		return

	if distance_traveled >= travel_distance:
		_land()

func _try_direct_patrol_hit() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is SpanishPatrol and enemy.current_state != SpanishPatrol.State.UNCONSCIOUS and global_position.distance_to(enemy.global_position) <= direct_hit_radius:
			enemy.knock_out(8.0)
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_temporary_notification"):
				hud.show_temporary_notification("Patrulla desmayada: 8 segundos", 2.0)
			queue_free()
			return true
	return false

func _land() -> void:
	if noise_area_scene:
		var noise_area = noise_area_scene.instantiate()
		noise_area.global_position = global_position
		get_parent().add_child(noise_area)
	queue_free()
