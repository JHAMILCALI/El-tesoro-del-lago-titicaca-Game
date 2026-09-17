extends CharacterBody2D
class_name EnemyBoat

signal player_caught(enemy: EnemyBoat)

enum State { PATROL, CHASE, LOST }

@export var patrol_speed: float = 80.0
@export var chase_speed: float = 125.0
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
	# La captura se calcula por distancia: los enemigos no deben bloquearse entre sí.
	collision_layer = 0
	collision_mask = 0
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
		_chase_player(distance)
		var level = get_tree().get_first_node_in_group("lake_level")
		if distance < 58.0 and _is_in_front_of_player() and capture_cooldown <= 0.0 and level and level.has_method("request_enemy_capture") and level.request_enemy_capture(self):
			capture_cooldown = 2.0
			player_caught.emit(self)
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

func _chase_player(distance: float) -> void:
	var direction := global_position.direction_to(player.global_position)
	var desired_velocity := Vector2.ZERO
	var is_lead_chaser := _is_closest_chaser(distance)
	var is_in_front := _is_in_front_of_player()
	if not is_in_front:
		# Por los costados acompaña sin atravesarse frente al rumbo del jugador.
		if distance < side_clearance:
			desired_velocity = -direction * chase_speed * 0.55 + direction.rotated(PI * 0.5) * chase_speed * 0.4
		else:
			desired_velocity = direction * patrol_speed
	elif is_lead_chaser and distance > 42.0:
		# Solo el perseguidor más cercano puede cerrar la distancia para capturar.
		desired_velocity = direction * chase_speed
	elif distance > follow_distance:
		desired_velocity = direction * chase_speed
	else:
		# Al llegar, rodea la barca en vez de montarse encima de ella.
		desired_velocity = -direction * chase_speed * 0.45 + direction.rotated(PI * 0.5) * chase_speed * 0.35
	for other in get_tree().get_nodes_in_group("enemy_boat"):
		if other == self or not other is Node2D or not other.visible:
			continue
		var other_boat := other as Node2D
		var separation: Vector2 = global_position - other_boat.global_position
		var separation_length: float = separation.length()
		if separation_length > 0.0 and separation_length < separation_distance:
			desired_velocity += separation.normalized() * chase_speed * (separation_distance - separation_length) / separation_distance
	velocity = desired_velocity.limit_length(chase_speed)
	if velocity.length() > 0.0:
		rotation = velocity.angle()
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
