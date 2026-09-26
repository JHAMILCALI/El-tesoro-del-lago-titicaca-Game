extends CharacterBody2D
class_name EnemyBoat

signal player_caught(enemy: EnemyBoat)

enum State { PATROL, CHASE, LOST }

const CAPTURE_FORWARD_REACH := 100.0
const CAPTURE_SIDE_REACH := 38.0
const CHASE_TURN_RATE := 2.8
const ESCORT_BLEND_DISTANCE := 90.0

@export var patrol_speed: float = 80.0
@export var chase_speed: float = 175.0
@export var chase_acceleration: float = 360.0
@export var detection_range: float = 300.0
@export var lose_range: float = 470.0
@export var follow_distance: float = 140.0
@export var separation_distance: float = 130.0
@export var side_clearance: float = 190.0
@export var patrol_points: Array[Vector2] = []

var state: State = State.PATROL
var patrol_index: int = 0
var player: Node2D
var current_target: Vector2
var home_position: Vector2
var capture_cooldown := 0.0

func _ready() -> void:
	add_to_group("enemy_boat")
	# La captura se calcula por distancia; solo el terreno sólido bloquea su avance.
	collision_layer = 0
	collision_mask = 1
	home_position = global_position
	player = get_tree().get_first_node_in_group("player") as Node2D
	if patrol_points.is_empty():
		patrol_points = [global_position + Vector2(0, 130), global_position + Vector2(120, 0)]
	current_target = patrol_points[0]

func _physics_process(delta: float) -> void:
	capture_cooldown = maxf(0.0, capture_cooldown - delta)
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		return
	var distance := global_position.distance_to(player.global_position)
	if distance < detection_range:
		state = State.CHASE
	elif state == State.CHASE and distance > lose_range:
		state = State.LOST
		current_target = patrol_points[patrol_index]
	elif state == State.LOST and distance > detection_range:
		state = State.PATROL

	if state == State.CHASE:
		current_target = player.global_position
		_chase_player(distance, delta)
		var level = get_tree().get_first_node_in_group("lake_level")
		if _is_head_on_contact() and capture_cooldown <= 0.0 and level and level.has_method("request_enemy_capture") and level.request_enemy_capture(self):
			capture_cooldown = 2.0
			player_caught.emit(self)
			return
		if level and level.has_method("set_enemy_pressure"):
			level.set_enemy_pressure(self, true, distance)
	else:
		_move_toward(current_target, patrol_speed)
		if global_position.distance_to(current_target) < 18.0:
			patrol_index = (patrol_index + 1) % patrol_points.size()
			current_target = patrol_points[patrol_index]
		var level = get_tree().get_first_node_in_group("lake_level")
		if level and level.has_method("set_enemy_pressure"):
			level.set_enemy_pressure(self, false, distance)
	var name_label := get_node_or_null("Label") as Label
	if name_label:
		name_label.rotation = -rotation

func _move_toward(target: Vector2, speed: float) -> void:
	velocity = global_position.direction_to(target) * speed
	if velocity.length() > 0.0:
		rotation = velocity.angle()
	move_and_slide()

func _chase_player(distance: float, delta: float) -> void:
	var direction := global_position.direction_to(player.global_position)
	var desired_velocity := Vector2.ZERO
	var is_lead_chaser := _is_closest_chaser(distance)
	var is_in_front := _is_in_front_of_player()
	if is_in_front and is_lead_chaser and distance > 42.0:
		# Solo el perseguidor más cercano puede cerrar la distancia para capturar.
		desired_velocity = direction * chase_speed
	else:
		# Cerca del jugador, la corrección radial cambia gradualmente y el bote
		# acompaña por un costado sin alternar entre avanzar y retroceder.
		var desired_distance := follow_distance if is_in_front else side_clearance
		var radial_error := distance - desired_distance
		var radial_factor := clampf(radial_error / ESCORT_BLEND_DISTANCE, -0.4, 1.0)
		var approach_speed := chase_speed if is_in_front else patrol_speed
		var radial_speed := radial_factor * (approach_speed if radial_factor >= 0.0 else chase_speed)
		var orbit_factor := 1.0 - clampf(radial_error / ESCORT_BLEND_DISTANCE, 0.0, 1.0)
		desired_velocity = direction * radial_speed + direction.orthogonal() * chase_speed * 0.35 * orbit_factor
	for other in get_tree().get_nodes_in_group("enemy_boat"):
		if other == self or not other is Node2D or not other.visible:
			continue
		var other_boat := other as Node2D
		var separation: Vector2 = global_position - other_boat.global_position
		var separation_length: float = separation.length()
		if separation_length > 0.0 and separation_length < separation_distance:
			desired_velocity += separation.normalized() * chase_speed * (separation_distance - separation_length) / separation_distance
	velocity = velocity.move_toward(desired_velocity.limit_length(chase_speed), chase_acceleration * delta)
	if velocity.length_squared() > 25.0:
		var angle_error := wrapf(velocity.angle() - rotation, -PI, PI)
		rotation += clampf(angle_error, -CHASE_TURN_RATE * delta, CHASE_TURN_RATE * delta)
	move_and_slide()

func _is_closest_chaser(my_distance: float) -> bool:
	for other in get_tree().get_nodes_in_group("enemy_boat"):
		if other == self or not other is EnemyBoat or not other.visible:
			continue
		if other.state == State.CHASE and other.global_position.distance_to(player.global_position) < my_distance - 4.0:
			return false
	return true

func _is_in_front_of_player() -> bool:
	var player_forward := Vector2.from_angle(player.rotation)
	var from_player_to_enemy := player.global_position.direction_to(global_position)
	# 0.55 equivale aproximadamente a un cono frontal de 113 grados.
	return player_forward.dot(from_player_to_enemy) > 0.55

func _is_head_on_contact() -> bool:
	var player_forward := Vector2.from_angle(player.rotation)
	var offset := global_position - player.global_position
	var forward_distance := offset.dot(player_forward)
	var side_distance := absf(player_forward.cross(offset))
	return forward_distance > 0.0 and forward_distance <= CAPTURE_FORWARD_REACH and side_distance <= CAPTURE_SIDE_REACH

func set_home_position(new_home: Vector2) -> void:
	home_position = new_home
	global_position = new_home
	state = State.PATROL
	patrol_index = 0
	patrol_points = [home_position + Vector2(0, 130), home_position + Vector2(120, 0)]
	current_target = patrol_points[0]
	velocity = Vector2.ZERO

func reset_to_patrol() -> void:
	set_home_position(home_position)
