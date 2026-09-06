extends CharacterBody2D
class_name BoatPrototype

@export var normal_speed: float = 150.0
@export var sprint_speed: float = 260.0
@export var rotation_speed: float = 3.0

var can_move: bool = true

func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current_speed := sprint_speed if Input.is_action_pressed("run") else normal_speed

	if input_vector != Vector2.ZERO:
		velocity = input_vector.normalized() * current_speed
		rotation = lerp_angle(rotation, input_vector.angle(), 0.15)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

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
