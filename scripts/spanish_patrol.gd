extends CharacterBody2D
class_name SpanishPatrol

enum State { PATROL, ALERT, CAPTURE }

signal player_captured

@export var speed: float = 80.0
@export var detection_duration: float = 1.8
@export var point_a: Vector2 = Vector2.ZERO
@export var point_b: Vector2 = Vector2(300, 0)

var current_state: State = State.PATROL
var target_point: Vector2
var is_player_in_area: bool = false
var detection_timer: float = 0.0
var target_player: Pasco = null

@onready var alert_label: Label = $AlertLabel
@onready var detection_area: Area2D = $DetectionArea

func _ready() -> void:
	target_point = point_b
	if alert_label:
		alert_label.visible = false

	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)

func _physics_process(delta: float) -> void:
	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.ALERT:
			_process_alert(delta)
		State.CAPTURE:
			_process_capture()

func _process_patrol(delta: float) -> void:
	if alert_label:
		alert_label.visible = false

	if detection_timer > 0.0:
		detection_timer = max(0.0, detection_timer - delta * 2.0)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("update_detection_progress"):
			hud.update_detection_progress(detection_timer / detection_duration)

	var move_vector := target_point - global_position
	if move_vector.length() > 5.0:
		var direction := move_vector.normalized()
		velocity = direction * speed
		if detection_area:
			detection_area.rotation = direction.angle()
	else:
		velocity = Vector2.ZERO
		target_point = point_a if target_point == point_b else point_b

	move_and_slide()

	if is_player_in_area and target_player and _has_line_of_sight(target_player):
		current_state = State.ALERT

func _process_alert(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if alert_label:
		alert_label.visible = true
		alert_label.text = "⚠ ALERTA"

	var hud = get_tree().get_first_node_in_group("hud")

	if is_player_in_area and target_player and _has_line_of_sight(target_player):
		detection_timer += delta
		if hud and hud.has_method("update_detection_progress"):
			hud.update_detection_progress(clampf(detection_timer / detection_duration, 0.0, 1.0))

		if detection_timer >= detection_duration:
			current_state = State.CAPTURE
	else:
		detection_timer -= delta * 1.5
		if hud and hud.has_method("update_detection_progress"):
			hud.update_detection_progress(clampf(detection_timer / detection_duration, 0.0, 1.0))

		if detection_timer <= 0.0:
			detection_timer = 0.0
			current_state = State.PATROL
			if alert_label:
				alert_label.visible = false
			if hud and hud.has_method("update_detection_progress"):
				hud.update_detection_progress(0.0)

func _process_capture() -> void:
	velocity = Vector2.ZERO
	if alert_label:
		alert_label.text = "¡Capturado!"
		alert_label.visible = true

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_detection_progress"):
		hud.update_detection_progress(0.0)
	if hud and hud.has_method("show_temporary_notification"):
		hud.show_temporary_notification("HAS SIDO DESCUBIERTO", 1.0)

	player_captured.emit()
	reset_patrol()

func reset_patrol() -> void:
	current_state = State.PATROL
	detection_timer = 0.0
	is_player_in_area = false
	target_player = null
	if alert_label:
		alert_label.visible = false

func _has_line_of_sight(player: Pasco) -> bool:
	if player == null or player.is_hidden:
		return false

	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [self.get_rid()]
	var result := space_state.intersect_ray(query)

	if result and result.size() > 0:
		var collider = result.get("collider")
		if collider == player or (collider != null and collider.is_in_group("player")):
			return true
		else:
			return false
	return true

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Pasco:
		target_player = body
		is_player_in_area = true
		if _has_line_of_sight(target_player):
			current_state = State.ALERT
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_temporary_notification"):
				hud.show_temporary_notification("⚠ ALERTA", 0.8)

func _on_detection_body_exited(body: Node2D) -> void:
	if body is Pasco:
		is_player_in_area = false
		target_player = null
