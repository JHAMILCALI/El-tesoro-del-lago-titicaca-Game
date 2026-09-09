extends CharacterBody2D
class_name SpanishPatrol

enum State { PATROL, SUSPICIOUS, INVESTIGATE, RETURN, ALERT, CAPTURE }

signal player_captured

@export var speed: float = 80.0
@export var investigate_speed: float = 95.0
@export var detection_duration: float = 1.5
@export var waypoint_wait_duration: float = 1.0
@export var point_a: Vector2 = Vector2.ZERO
@export var point_b: Vector2 = Vector2(300, 0)

var current_state: State = State.PATROL
var target_point: Vector2
var investigate_target_pos: Vector2
var is_player_in_area: bool = false
var detection_timer: float = 0.0
var state_timer: float = 0.0
var is_waiting_at_waypoint: bool = false

@onready var alert_label: Label = $AlertLabel
@onready var detection_visual: Polygon2D = $DetectionArea/DetectionVisual
@onready var raycast: RayCast2D = $RayCast2D

func _ready() -> void:
	add_to_group("enemies")
	target_point = point_b
	if alert_label:
		alert_label.visible = false
	var detection_area = get_node_or_null("DetectionArea")
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)

func _physics_process(delta: float) -> void:
	_update_vision_cone_color()

	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.SUSPICIOUS:
			_process_suspicious(delta)
		State.INVESTIGATE:
			_process_investigate(delta)
		State.RETURN:
			_process_return(delta)
		State.ALERT:
			_process_alert(delta)
		State.CAPTURE:
			_process_capture()

func _process_patrol(delta: float) -> void:
	if alert_label:
		alert_label.visible = false

	if is_waiting_at_waypoint:
		velocity = Vector2.ZERO
		state_timer += delta
		rotation = lerp_angle(rotation, (target_point - global_position).angle(), delta * 3.0)
		if state_timer >= waypoint_wait_duration:
			is_waiting_at_waypoint = false
			state_timer = 0.0
		_check_player_detection(delta)
		return

	var direction := (target_point - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	if direction != Vector2.ZERO:
		rotation = lerp_angle(rotation, direction.angle(), delta * 7.0)

	if global_position.distance_to(target_point) < 12.0:
		target_point = point_a if target_point == point_b else point_b
		is_waiting_at_waypoint = true
		state_timer = 0.0

	_check_player_detection(delta)

func _process_suspicious(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	var look_angle = (investigate_target_pos - global_position).angle()
	rotation = lerp_angle(rotation, look_angle, delta * 9.0)

	if alert_label:
		alert_label.visible = true
		alert_label.text = "¿Qué fue eso?"

	state_timer += delta
	if state_timer >= 0.8:
		state_timer = 0.0
		current_state = State.INVESTIGATE

	_check_player_detection(delta)

func _process_investigate(delta: float) -> void:
	if alert_label:
		alert_label.visible = true
		alert_label.text = "Investigando..."

	var direction := (investigate_target_pos - global_position).normalized()
	if global_position.distance_to(investigate_target_pos) > 15.0:
		velocity = direction * investigate_speed
		move_and_slide()
		if direction != Vector2.ZERO:
			rotation = lerp_angle(rotation, direction.angle(), delta * 7.0)
	else:
		velocity = Vector2.ZERO
		state_timer += delta
		# Look side to side
		rotation = lerp_angle(rotation, direction.angle() + sin(state_timer * 6.0) * 0.5, delta * 5.0)
		if state_timer >= 1.8:
			state_timer = 0.0
			current_state = State.RETURN

	_check_player_detection(delta)

func _process_return(delta: float) -> void:
	if alert_label:
		alert_label.visible = true
		alert_label.text = "Volviendo..."

	var direction := (target_point - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	if direction != Vector2.ZERO:
		rotation = lerp_angle(rotation, direction.angle(), delta * 7.0)

	if global_position.distance_to(target_point) < 15.0:
		if alert_label:
			alert_label.visible = false
		current_state = State.PATROL

	_check_player_detection(delta)

func _process_alert(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	var pasco = get_tree().get_first_node_in_group("player")
	if pasco:
		var look_angle = (pasco.global_position - global_position).angle()
		rotation = lerp_angle(rotation, look_angle, delta * 10.0)

	if alert_label:
		alert_label.visible = true
		alert_label.text = "¡Alerta!"

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_temporary_notification"):
		hud.show_temporary_notification("¡Alerta!", 0.2)

	_check_player_detection(delta)

func _process_capture() -> void:
	velocity = Vector2.ZERO
	if alert_label:
		alert_label.text = "¡Capturado!"
		alert_label.visible = true

	player_captured.emit()
	reset_patrol()

func reset_patrol() -> void:
	current_state = State.PATROL
	detection_timer = 0.0
	state_timer = 0.0
	is_player_in_area = false
	is_waiting_at_waypoint = false
	if alert_label:
		alert_label.visible = false

func on_noise_heard(noise_pos: Vector2) -> void:
	if current_state in [State.PATROL, State.RETURN, State.SUSPICIOUS]:
		investigate_target_pos = noise_pos
		state_timer = 0.0
		is_waiting_at_waypoint = false
		current_state = State.SUSPICIOUS

func _update_vision_cone_color() -> void:
	if not detection_visual:
		return

	match current_state:
		State.PATROL, State.RETURN:
			detection_visual.color = Color(1.0, 0.9, 0.4, 0.25)
		State.SUSPICIOUS, State.INVESTIGATE:
			detection_visual.color = Color(1.0, 0.5, 0.1, 0.35)
		State.ALERT, State.CAPTURE:
			detection_visual.color = Color(1.0, 0.15, 0.15, 0.5)

func _check_player_detection(delta: float) -> void:
	if not is_player_in_area:
		if current_state == State.ALERT:
			current_state = State.PATROL
			detection_timer = 0.0
		return

	var pasco = get_tree().get_first_node_in_group("player")
	if not pasco or pasco.get("is_hidden") == true:
		if current_state == State.ALERT:
			current_state = State.PATROL
			detection_timer = 0.0
		return

	# Line of sight raycast check
	if raycast:
		raycast.target_position = raycast.to_local(pasco.global_position)
		raycast.force_raycast_update()
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider != pasco and not (collider is CharacterBody2D and collider.is_in_group("player")):
				# Obscured by wall
				if current_state == State.ALERT:
					current_state = State.PATROL
					detection_timer = 0.0
				return

	# Pasco is visible in detection area and clear Line of Sight
	current_state = State.ALERT
	detection_timer += delta
	if detection_timer >= detection_duration:
		current_state = State.CAPTURE

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Pasco:
		is_player_in_area = true
		detection_timer = 0.0

func _on_detection_body_exited(body: Node2D) -> void:
	if body is Pasco:
		is_player_in_area = false
		detection_timer = 0.0
