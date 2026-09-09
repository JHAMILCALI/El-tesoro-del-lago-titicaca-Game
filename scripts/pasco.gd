extends CharacterBody2D
class_name Pasco

signal stone_count_changed(new_count: int)

@export var walk_speed: float = 180.0
@export var run_speed: float = 280.0
@export var stone_travel_distance: float = 180.0
@export var initial_stones: int = 3
@export var max_stones: int = 10

var can_move: bool = true
var is_hidden: bool = false
var hide_area_count: int = 0
var last_direction: Vector2 = Vector2.RIGHT
var can_throw_stone: bool = true
var stone_count: int = 3

var stone_scene: PackedScene = preload("res://scenes/objects/Stone.tscn")

@onready var aim_line: Line2D = $AimLine
@onready var aim_target: Node2D = $AimTarget

func _ready() -> void:
	add_to_group("player")
	stone_count = initial_stones
	_ensure_input_actions()
	call_deferred("_sync_hud_stones")

func _process(_delta: float) -> void:
	_update_aim_indicator()

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current_speed := run_speed if Input.is_action_pressed("run") else walk_speed

	if input_vector != Vector2.ZERO:
		velocity = input_vector.normalized() * current_speed
		last_direction = input_vector.normalized()
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("throw_stone") and can_move:
		get_viewport().set_input_as_handled()
		if stone_count <= 0:
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_temporary_notification"):
				hud.show_temporary_notification("Sin piedras. Busca más en el camino.", 2.0)
			return

		if can_throw_stone:
			_throw_stone()

func _update_aim_indicator() -> void:
	if not aim_line or not aim_target:
		return

	var is_aim_visible = can_throw_stone and can_move and stone_count > 0
	aim_line.visible = is_aim_visible
	aim_target.visible = is_aim_visible

	if not is_aim_visible:
		return

	var start_pos := Vector2.ZERO
	var end_pos := last_direction.normalized() * stone_travel_distance

	aim_line.clear_points()
	aim_line.add_point(start_pos)
	aim_line.add_point(end_pos)

	aim_target.position = end_pos
	aim_target.rotation = last_direction.angle()

func _throw_stone() -> void:
	if not stone_scene or stone_count <= 0:
		return

	can_throw_stone = false
	stone_count -= 1
	_sync_hud_stones()

	var stone = stone_scene.instantiate()
	stone.global_position = global_position
	stone.setup(last_direction)
	get_parent().add_child(stone)

	get_tree().create_timer(0.8).timeout.connect(func():
		can_throw_stone = true
	)

func add_stones(amount: int) -> void:
	stone_count = clampi(stone_count + amount, 0, max_stones)
	_sync_hud_stones()

func _sync_hud_stones() -> void:
	stone_count_changed.emit(stone_count)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_stone_count"):
		hud.update_stone_count(stone_count)

func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled
	if not enabled:
		velocity = Vector2.ZERO

func enter_hide_area() -> void:
	hide_area_count += 1
	is_hidden = hide_area_count > 0

func exit_hide_area() -> void:
	hide_area_count = maxi(0, hide_area_count - 1)
	is_hidden = hide_area_count > 0

func clear_hide_state() -> void:
	hide_area_count = 0
	is_hidden = false

func _ensure_input_actions() -> void:
	var actions := {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"run": [KEY_SHIFT],
		"interact": [KEY_E, KEY_ENTER],
		"throw_stone": [KEY_Q],
		"pause": [KEY_ESCAPE]
	}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for key_code in actions[action_name]:
				var ev := InputEventKey.new()
				ev.physical_keycode = key_code
				InputMap.action_add_event(action_name, ev)
