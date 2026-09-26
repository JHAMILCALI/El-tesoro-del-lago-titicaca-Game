extends Node2D
class_name LocalVillager

enum Activity { WALK, WEAVE, FISH, REST }
enum GrassSide { NORTH, SOUTH }

@export var appearance: Texture2D
@export var activity: Activity = Activity.WALK
@export var grass_side: GrassSide = GrassSide.NORTH
@export var walk_speed: float = 22.0
@export var wander_radius: float = 38.0
@export var spanish_clearance: float = 205.0

var home: Vector2
var destination: Vector2
var pause_remaining: float = 0.0
var motion_time: float = 0.0
var rng := RandomNumberGenerator.new()

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("local_villagers")
	home = global_position
	rng.seed = int(absf(home.x * 37.0 + home.y * 101.0)) + 1
	pause_remaining = rng.randf_range(0.5, 2.5)
	destination = _on_grass(home + Vector2(rng.randf_range(-wander_radius, wander_radius), rng.randf_range(-13.0, 13.0)))
	sprite.texture = appearance

func _physics_process(delta: float) -> void:
	motion_time += delta
	var nearest_spanish := _nearest_active_spanish()
	if nearest_spanish != null and global_position.distance_to(nearest_spanish.global_position) < spanish_clearance:
		var away := global_position - nearest_spanish.global_position
		if away.length_squared() < 0.01:
			away = Vector2.UP if grass_side == GrassSide.NORTH else Vector2.DOWN
		var retreat := global_position + away.normalized() * walk_speed * 1.8 * delta
		global_position = _on_grass(retreat)
		destination = global_position
		pause_remaining = 0.8
		_animate(true)
		return

	if pause_remaining > 0.0:
		pause_remaining -= delta
		_animate(false)
		return

	if global_position.distance_to(destination) <= 3.0:
		pause_remaining = rng.randf_range(1.8, 4.0) if activity == Activity.WALK else rng.randf_range(3.5, 6.0)
		var offset := Vector2(rng.randf_range(-wander_radius, wander_radius), rng.randf_range(-13.0, 13.0))
		destination = _on_grass(home + offset)
		_animate(false)
		return

	var next_position := global_position.move_toward(destination, walk_speed * delta)
	global_position = _on_grass(next_position)
	sprite.flip_h = destination.x < global_position.x
	_animate(true)

func _on_grass(point: Vector2) -> Vector2:
	var y_min := 35.0 if grass_side == GrassSide.NORTH else 585.0
	var y_max := 95.0 if grass_side == GrassSide.NORTH else 655.0
	return Vector2(clampf(point.x, home.x - wander_radius, home.x + wander_radius), clampf(point.y, y_min, y_max))

func _nearest_active_spanish() -> SpanishPatrol:
	var nearest: SpanishPatrol = null
	var nearest_distance := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is SpanishPatrol and node.current_state != SpanishPatrol.State.UNCONSCIOUS:
			var distance := global_position.distance_squared_to(node.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = node
	return nearest

func _animate(walking: bool) -> void:
	var bob := sin(motion_time * 9.0) * 2.0 if walking else 0.0
	if not walking and activity != Activity.REST:
		bob = sin(motion_time * 2.2) * 0.8
	sprite.position.y = -1.0 + bob
	if activity == Activity.WEAVE and not walking:
		sprite.rotation = sin(motion_time * 3.0) * 0.018
	elif activity == Activity.FISH and not walking:
		sprite.rotation = sin(motion_time * 1.5) * 0.012
	else:
		sprite.rotation = 0.0
