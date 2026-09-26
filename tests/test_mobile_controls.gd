extends SceneTree

var failures := 0
var mobile: Node

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func touch(index: int, position: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func settle() -> void:
	for frame in 4:
		await process_frame

func run_checks() -> void:
	root.size = Vector2i(1280, 720)
	mobile = root.get_node("MobileControls")
	mobile.enabled = true
	change_scene_to_file("res://scenes/levels/Level01_Convoy.tscn")
	await settle()
	var pasco: Pasco = current_scene.get_node("Pasco")
	var initial_position := pasco.position
	var initial_stones := pasco.stone_count
	var joystick: Vector2 = mobile.joystick_center()
	touch(0, joystick, true)
	drag(0, joystick + Vector2(95, 0))
	touch(1, mobile.button_center("run"), true)
	await create_timer(0.2).timeout
	check(pasco.position.x > initial_position.x + 20, "Touch joystick did not move Pasco")
	check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"), "Multiple fingers did not hold movement and run together")
	check(pasco.stone_count == initial_stones, "Moving or running consumed a stone")
	touch(1, mobile.button_center("run"), false)
	check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("run"), "Releasing run canceled the other finger")
	touch(0, joystick, false)
	check(not Input.is_action_pressed("move_right"), "Joystick remained held after release")
	var throw_button: Vector2 = mobile.button_center("throw")
	touch(2, throw_button, true)
	drag(2, throw_button + Vector2(-100, -100))
	check(pasco._get_mouse_aim().dir.dot(Vector2(-1, -1).normalized()) > 0.99, "Touch drag did not control stone aim")
	touch(2, throw_button, false)
	await create_timer(0.16).timeout
	check(pasco.stone_count == initial_stones - 1, "Release should throw exactly one stone")
	var thrown := false
	for child in current_scene.get_children():
		if child is Stone:
			thrown = true
			check(child.direction.dot(Vector2(-1, -1).normalized()) > 0.99, "Stone did not use the chosen touch direction")
	check(thrown, "No stone spawned after aiming")
	touch(3, throw_button, true)
	touch(3, throw_button, false, true)
	check(not mobile.aiming and pasco.stone_count == initial_stones - 1, "Canceled touch threw a stone")
	touch(0, joystick, true)
	drag(0, joystick + Vector2(100, 0))
	touch(1, mobile.button_center("run"), true)
	touch(4, mobile.button_center("pause"), true)
	check(paused and not Input.is_action_pressed("move_right") and not Input.is_action_pressed("run"), "Pause did not clear held controls")
	touch(4, mobile.button_center("pause"), false)
	touch(5, mobile.pause_rect(0).get_center(), true)
	await settle()
	check(not paused, "Touch Continue did not resume pause")
	touch(5, mobile.pause_rect(0).get_center(), false)
	# The actual dialogue must advance from ACTION, without consuming stones.
	var dialogue: DialogueBox = current_scene.get_node("DialogueBox")
	dialogue.start_dialogue([{"speaker": "Huita", "text": "Prueba de diálogo táctil."}])
	await settle()
	touch(6, mobile.button_center("continue"), true)
	await settle()
	check(not dialogue.is_active and pasco.can_move, "Touch Continue did not finish dialogue")
	check(pasco.stone_count == initial_stones - 1, "Dialogue tap consumed a stone")
	touch(6, mobile.button_center("continue"), false)
	# Scene transitions must clear old finger ownership.
	touch(0, mobile.joystick_center(), true)
	drag(0, mobile.joystick_center() + Vector2(100, 0))
	change_scene_to_file("res://scenes/levels/LakeLevel02.tscn")
	await settle()
	check(mobile.fingers.is_empty() and not Input.is_action_pressed("move_right"), "Scene transition left movement pressed")
	dialogue = current_scene.get_node("DialogueBox")
	for line in 4:
		touch(6, mobile.button_center("continue"), true)
		await settle()
		touch(6, mobile.button_center("continue"), false)
	check(not dialogue.is_active, "Lake introduction is not touch playable")
	var boat: BoatPrototype = current_scene.get_node("BoatPrototype/Boat")
	var boat_start := boat.position
	joystick = mobile.joystick_center()
	touch(0, joystick, true)
	drag(0, joystick + Vector2(0, -100))
	touch(1, mobile.button_center("run"), true)
	await create_timer(0.35).timeout
	check(boat.position.distance_to(boat_start) > 5, "Touch joystick did not move the boat")
	check(boat.resistencia < boat.max_stamina, "Touch boost did not engage fast rowing")
	mobile._on_resize()
	check(not Input.is_action_pressed("move_up") and not Input.is_action_pressed("run"), "Resize left a touch action stuck")
	mobile.release_all()
	# Turning the phone and leaving the app must pause safely and clear fingers.
	root.size = Vector2i(720, 1280)
	await settle()
	check(paused and mobile.orientation_paused, "Portrait orientation did not pause play")
	root.size = Vector2i(1280, 720)
	await settle()
	check(not paused, "Landscape orientation did not resume play")
	mobile._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(paused and mobile.manual_paused, "Losing app focus did not pause play")
	mobile._pause_choice(0)
	# Mouse and keyboard remain available in the desktop layout.
	mobile.enabled = false
	change_scene_to_file("res://scenes/levels/Level01_Convoy.tscn")
	await settle()
	pasco = current_scene.get_node("Pasco")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = Vector2(750, 350)
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	check(pasco.stone_count == pasco.initial_stones - 1, "Desktop mouse no longer throws stones")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	check(paused, "Keyboard pause no longer works")
	mobile._pause_choice(0)
	paused = false
	print("MOBILE_CONTROLS_TESTS: ", failures, " failures")
	quit(1 if failures else 0)
