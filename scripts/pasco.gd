extends CharacterBody2D
class_name Pasco

@export var walk_speed: float = 180.0
@export var run_speed: float = 280.0

var can_move: bool = true

func _ready() -> void:
	_ensure_input_actions()

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current_speed := run_speed if Input.is_action_pressed("run") else walk_speed

	if input_vector != Vector2.ZERO:
		velocity = input_vector.normalized() * current_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled
	if not enabled:
		velocity = Vector2.ZERO

func _ensure_input_actions() -> void:
	# Fallback key registration if not loaded from project.godot
	var actions := {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"run": [KEY_SHIFT],
		"interact": [KEY_E, KEY_ENTER],
		"pause": [KEY_ESCAPE]
	}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for key_code in actions[action_name]:
				var ev := InputEventKey.new()
				ev.physical_keycode = key_code
				InputMap.action_add_event(action_name, ev)
