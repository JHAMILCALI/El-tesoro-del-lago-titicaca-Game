extends Node2D
class_name LocalVillager

enum Activity { WALK, WEAVE, FISH, REST }

const WALK_FRAMES := 4
const WALK_FPS := 7.0

@export var appearance: Texture2D
@export var activity: Activity = Activity.WALK
@export var route_start: Vector2
@export var route_end: Vector2
@export var walk_speed: float = 34.0
@export var spanish_clearance: float = 155.0

var destination: Vector2
var pause_remaining: float = 0.0
var motion_time: float = 0.0
var walk_elapsed: float = 0.0
var current_walk_frame: int = 1
var rng := RandomNumberGenerator.new()

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("local_villagers")
	rng.seed = int(absf(global_position.x * 37.0 + global_position.y * 101.0)) + 1
	if route_start.is_equal_approx(route_end):
		route_start = global_position
		route_end = global_position + Vector2(300.0, 0.0)
	destination = route_end if global_position.distance_to(route_start) <= global_position.distance_to(route_end) else route_start
	pause_remaining = rng.randf_range(0.2, 1.1)
	sprite.texture = appearance
	sprite.region_enabled = true
	sprite.region_filter_clip_enabled = true
	_set_frame(1)

func _physics_process(delta: float) -> void:
	motion_time += delta
	var nearest_spanish := _nearest_active_spanish()
	if nearest_spanish != null and global_position.distance_to(nearest_spanish.global_position) < spanish_clearance:
		var retreat_target := route_start if route_start.distance_to(nearest_spanish.global_position) > route_end.distance_to(nearest_spanish.global_position) else route_end
		destination = retreat_target
		pause_remaining = 0.0
		_move_to_destination(delta, walk_speed * 1.45)
		return

	if pause_remaining > 0.0:
		pause_remaining -= delta
		_animate(false, delta)
		return

	if global_position.distance_to(destination) <= 3.0:
		destination = route_start if destination.is_equal_approx(route_end) else route_end
		pause_remaining = rng.randf_range(1.1, 2.0) if activity == Activity.WALK else rng.randf_range(2.5, 4.0)
		_animate(false, delta)
		return

	_move_to_destination(delta, walk_speed)

func _move_to_destination(delta: float, speed: float) -> void:
	var previous_position := global_position
	sprite.flip_h = destination.x < global_position.x
	global_position = global_position.move_toward(destination, speed * delta)
	_animate(global_position.distance_squared_to(previous_position) > 0.001, delta)

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

func _animate(walking: bool, delta: float) -> void:
	if walking:
		walk_elapsed += delta * WALK_FPS
		_set_frame(int(walk_elapsed) % WALK_FRAMES)
		sprite.position.y = -1.0 + sin(motion_time * 14.0) * 0.8
		sprite.rotation = 0.0
		return

	walk_elapsed = 0.0
	_set_frame(1)
	sprite.position.y = -1.0 + sin(motion_time * 2.2) * 0.6
	if activity == Activity.WEAVE:
		sprite.rotation = sin(motion_time * 3.0) * 0.018
	elif activity == Activity.FISH:
		sprite.rotation = sin(motion_time * 1.5) * 0.012
	else:
		sprite.rotation = 0.0

func _set_frame(frame: int) -> void:
	if appearance == null:
		return
	current_walk_frame = frame
	var frame_width := appearance.get_width() / WALK_FRAMES
	sprite.region_rect = Rect2(frame * frame_width, 0, frame_width, appearance.get_height())
