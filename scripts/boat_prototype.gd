extends CharacterBody2D
class_name BoatPrototype

signal stamina_changed(current: float, maximum: float)
signal speed_changed(current: float)
signal impact_received

@export var normal_speed: float = 150.0
@export var sprint_speed: float = 260.0
@export var acceleration: float = 330.0
@export var braking: float = 260.0
@export var rotation_speed: float = 5.0
@export var max_stamina: float = 100.0
@export var stamina_drain_per_second: float = 28.0
@export var stamina_recovery_per_second: float = 18.0

var can_move: bool = true
var velocidad_actual: float = 0.0
var resistencia: float = 100.0
var external_force: Vector2 = Vector2.ZERO
var impact_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()
	_disable_passenger_controls()
	resistencia = max_stamina
	stamina_changed.emit(resistencia, max_stamina)

func _disable_passenger_controls() -> void:
	for passenger_name in ["Pasco", "Huita"]:
		var passenger := get_node_or_null("Passengers/" + passenger_name)
		if passenger:
			passenger.process_mode = Node.PROCESS_MODE_DISABLED
			if passenger is CollisionObject2D:
				passenger.collision_layer = 0
				passenger.collision_mask = 0

func _physics_process(delta: float) -> void:
	impact_cooldown = maxf(0.0, impact_cooldown - delta)
	if not can_move:
		velocity = external_force
		move_and_slide()
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var using_fast_rowing := Input.is_action_pressed("run") and input_vector != Vector2.ZERO and resistencia > 0.0
	var target_speed := normal_speed
	if using_fast_rowing:
		target_speed = sprint_speed
		resistencia = maxf(0.0, resistencia - stamina_drain_per_second * delta)
	else:
		resistencia = minf(max_stamina, resistencia + stamina_recovery_per_second * delta)
	stamina_changed.emit(resistencia, max_stamina)

	if input_vector != Vector2.ZERO:
		velocidad_actual = move_toward(velocidad_actual, target_speed, acceleration * delta)
		rotation = lerp_angle(rotation, input_vector.angle(), minf(1.0, rotation_speed * delta))
	else:
		velocidad_actual = move_toward(velocidad_actual, 0.0, braking * delta)

	var direction := input_vector.normalized() if input_vector != Vector2.ZERO else Vector2.from_angle(rotation)
	velocity = direction * velocidad_actual + external_force
	move_and_slide()
	external_force = external_force.move_toward(Vector2.ZERO, 100.0 * delta)
	speed_changed.emit(velocidad_actual)

func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled
	if not enabled:
		velocidad_actual = 0.0

func apply_current(force: Vector2) -> void:
	external_force = force

func apply_impact(from_position: Vector2) -> void:
	if impact_cooldown > 0.0:
		return
	impact_cooldown = 0.7
	velocidad_actual *= 0.35
	var push_direction := (global_position - from_position).normalized()
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.RIGHT
	external_force = push_direction * 180.0
	rotation += randf_range(-0.32, 0.32)
	impact_received.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")

func _ensure_input_actions() -> void:
	var actions := {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"run": [KEY_SHIFT],
		"pause": [KEY_ESCAPE]
	}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for key_code in actions[action_name]:
				var ev := InputEventKey.new()
				ev.physical_keycode = key_code
				InputMap.action_add_event(action_name, ev)
