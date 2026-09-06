extends CharacterBody2D
class_name SpanishPatrol

enum State { PATROL, ALERT, CAPTURE }

signal player_captured

@export var speed: float = 80.0
@export var detection_duration: float = 1.5
@export var point_a: Vector2 = Vector2.ZERO
@export var point_b: Vector2 = Vector2(300, 0)

var current_state: State = State.PATROL
var target_point: Vector2
var is_player_in_area: bool = false
var detection_timer: float = 0.0

@onready var alert_label: Label = $AlertLabel

func _ready() -> void:
	target_point = point_b
	if alert_label:
		alert_label.visible = false
	var detection_area = get_node_or_null("DetectionArea")
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

func _process_patrol(_delta: float) -> void:
	if alert_label:
		alert_label.visible = false

	var direction := (target_point - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	if global_position.distance_to(target_point) < 10.0:
		target_point = point_a if target_point == point_b else point_b

func _process_alert(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if alert_label:
		alert_label.visible = true
		alert_label.text = "¡Alerta!"

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_temporary_notification"):
		hud.show_temporary_notification("¡Alerta!", 0.2)

	if is_player_in_area:
		detection_timer += delta
		if detection_timer >= detection_duration:
			current_state = State.CAPTURE
	else:
		current_state = State.PATROL
		detection_timer = 0.0
		if alert_label:
			alert_label.visible = false

func _process_capture() -> void:
	velocity = Vector2.ZERO
	if alert_label:
		alert_label.text = "¡Capturado!"
		alert_label.visible = true

	player_captured.emit()

	# Reset state after capture event
	current_state = State.PATROL
	detection_timer = 0.0
	is_player_in_area = false
	if alert_label:
		alert_label.visible = false

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Pasco:
		is_player_in_area = true
		detection_timer = 0.0
		current_state = State.ALERT

func _on_detection_body_exited(body: Node2D) -> void:
	if body is Pasco:
		is_player_in_area = false
		detection_timer = 0.0
		current_state = State.PATROL
		if alert_label:
			alert_label.visible = false
