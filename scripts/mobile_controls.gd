extends CanvasLayer
## Shared multi-touch controls. Each finger owns one control until release.

signal touch_mode_changed

const MOVE_ACTIONS := [&"move_left", &"move_right", &"move_up", &"move_down"]
const GOLD := Color("e6ba70")
const INK := Color(0.08, 0.10, 0.11, 0.80)
const JOY_RADIUS := 105.0
const BUTTON_RADIUS := 66.0

class TouchSurface extends Control:
	var host: CanvasLayer
	func _draw() -> void:
		host.draw_controls(self)

var enabled := false
var can_fullscreen := true
var surface: TouchSurface
var fingers: Dictionary = {}
var stick := Vector2.ZERO
var aim_direction := Vector2.RIGHT
var aim_distance_ratio := 1.0
var aiming := false
var aim_origin := Vector2.ZERO
var scene: Node
var player: Node2D
var dialogue: Node
var hud: Node
var mode := ""
var manual_paused := false
var orientation_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	enabled = DisplayServer.is_touchscreen_available() or "--touch" in OS.get_cmdline_user_args()
	if OS.has_feature("web"):
		enabled = enabled or bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0 || new URLSearchParams(location.search).get('touch') === '1'"))
	if OS.has_feature("web"):
		can_fullscreen = bool(JavaScriptBridge.eval("!!document.documentElement.requestFullscreen"))
	surface = TouchSurface.new()
	surface.host = self
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_on_resize)

func _process(_delta: float) -> void:
	if scene != get_tree().current_scene:
		release_all()
		manual_paused = false
		orientation_paused = false
		get_tree().paused = false
		scene = get_tree().current_scene
		player = null
		dialogue = null
		hud = null
		if is_instance_valid(scene):
			player = scene.get_node_or_null("Pasco")
			if not player:
				player = scene.get_node_or_null("BoatPrototype/Boat")
			dialogue = scene.get_node_or_null("DialogueBox")
			hud = scene.get_node_or_null("HUD")
	var new_mode := _get_mode()
	if new_mode != mode:
		release_all()
		mode = new_mode
	_update_orientation()
	surface.visible = not mode.is_empty() and (enabled or manual_paused)
	surface.queue_redraw()

func _get_mode() -> String:
	if not is_instance_valid(player) or not is_instance_valid(hud) or not hud.visible:
		return ""
	if hud.alpha_complete_panel.visible:
		return "complete"
	if is_instance_valid(dialogue) and dialogue.is_active:
		return "dialogue"
	if not player.can_move:
		return "locked"
	return "boat" if player is BoatPrototype else "walk"

func _on_resize() -> void:
	release_all()
	_update_orientation()

func _update_orientation() -> void:
	var portrait := enabled and not mode.is_empty() and get_viewport().get_visible_rect().size.x < get_viewport().get_visible_rect().size.y
	if portrait != orientation_paused:
		release_all()
		orientation_paused = portrait
		get_tree().paused = manual_paused or orientation_paused

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()
		if is_instance_valid(player) and not mode.is_empty():
			manual_paused = true
			get_tree().paused = true

func joystick_center() -> Vector2:
	return Vector2(165, get_viewport().get_visible_rect().size.y - 150)

func button_center(which: String) -> Vector2:
	var size := get_viewport().get_visible_rect().size
	match which:
		"run": return size - Vector2(325, 130)
		"interact": return size - Vector2(155, 130)
		"throw": return size - Vector2(155, 290)
		"pause": return Vector2(size.x - 82, 68)
		"fullscreen": return Vector2(size.x - 218, 68)
		"continue": return size - Vector2(190, 70)
	return Vector2.ZERO

func pause_rect(index: int) -> Rect2:
	var center := get_viewport().get_visible_rect().size * 0.5
	return Rect2(center + Vector2(-220, -70 + index * 110), Vector2(440, 90))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not enabled:
		enabled = true
		touch_mode_changed.emit()
	if mode.is_empty():
		return
	if event.is_action_pressed("pause") and not event.is_echo():
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			if _press(event.index, event.position):
				get_viewport().set_input_as_handled()
		else:
			if fingers.has(event.index):
				_release(event.index, event.canceled)
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		_drag(event.index, event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Mouse support also makes the touch layout testable on a desktop.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if event.pressed:
			if (enabled or manual_paused) and _press(-1, event.position):
				get_viewport().set_input_as_handled()
		elif fingers.has(-1):
			_release(-1, false)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and fingers.has(-1):
		_drag(-1, event.position)
		get_viewport().set_input_as_handled()

func _press(index: int, position: Vector2) -> bool:
	if orientation_paused:
		return true
	if manual_paused:
		for choice in 3:
			if pause_rect(choice).has_point(position):
				_pause_choice.call_deferred(choice)
		return true
	if position.distance_to(button_center("pause")) < 56.0:
		_toggle_pause()
		return true
	if can_fullscreen and position.distance_to(button_center("fullscreen")) < 56.0:
		_fullscreen()
		return true
	if mode == "dialogue":
		var continue_rect := Rect2(button_center("continue") - Vector2(170, 48), Vector2(340, 96))
		if continue_rect.has_point(position):
			_tap_action.call_deferred(&"interact")
		return true
	if mode not in ["walk", "boat"]:
		return false
	if position.distance_to(joystick_center()) <= JOY_RADIUS + 35.0 and not fingers.values().has("move"):
		fingers[index] = "move"
		_drag(index, position)
		return true
	for which in ["run", "interact", "throw"]:
		if which == "throw" and mode != "walk":
			continue
		if position.distance_to(button_center(which)) > BUTTON_RADIUS + 8.0:
			continue
		if fingers.values().has(which):
			return true
		fingers[index] = which
		if which == "run":
			Input.action_press("run")
		elif which == "interact":
			_tap_action.call_deferred(&"interact")
		elif which == "throw":
			aiming = true
			aim_origin = position
			aim_direction = player.last_direction
			aim_distance_ratio = 1.0
		return true
	return false

func _drag(index: int, position: Vector2) -> void:
	match fingers.get(index, ""):
		"move":
			stick = ((position - joystick_center()) / JOY_RADIUS).limit_length()
			if stick.length() < 0.16:
				stick = Vector2.ZERO
			_set_strength(&"move_left", maxf(0.0, -stick.x))
			_set_strength(&"move_right", maxf(0.0, stick.x))
			_set_strength(&"move_up", maxf(0.0, -stick.y))
			_set_strength(&"move_down", maxf(0.0, stick.y))
		"throw":
			var drag := position - aim_origin
			if drag.length() > 12.0:
				aim_direction = drag.normalized()
				aim_distance_ratio = clampf(drag.length() / 120.0, 0.25, 1.0)

func _set_strength(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)

func _release(index: int, canceled: bool) -> void:
	var which: String = fingers.get(index, "")
	fingers.erase(index)
	if which == "move":
		stick = Vector2.ZERO
		for action in MOVE_ACTIONS:
			Input.action_release(action)
	elif which == "run":
		Input.action_release("run")
	elif which == "throw":
		# Dispatch while the final aim is still available to Pasco.
		if not canceled and mode == "walk" and is_instance_valid(player) and player.can_move:
			_tap_action(&"throw_stone")
		aiming = false

func release_all() -> void:
	for index in fingers.keys():
		_release(index, true)
	stick = Vector2.ZERO
	aiming = false

func _tap_action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	get_viewport().push_input(event, true)
	event = InputEventAction.new()
	event.action = action
	get_viewport().push_input(event, true)

func _toggle_pause() -> void:
	release_all()
	manual_paused = not manual_paused
	get_tree().paused = manual_paused or orientation_paused

func _pause_choice(choice: int) -> void:
	release_all()
	manual_paused = false
	get_tree().paused = orientation_paused
	if choice == 1:
		get_tree().paused = false
		get_tree().reload_current_scene()
	elif choice == 2:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")

func _fullscreen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (!document.fullscreenElement && document.documentElement.requestFullscreen) { document.documentElement.requestFullscreen().then(() => { if (screen.orientation && screen.orientation.lock) screen.orientation.lock('landscape').catch(() => {}); }).catch(() => {}); }")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func draw_controls(canvas: Control) -> void:
	var screen := get_viewport().get_visible_rect().size
	if orientation_paused:
		canvas.draw_rect(Rect2(Vector2.ZERO, screen), Color(0.04, 0.06, 0.08, 0.97))
		_text(canvas, screen * 0.5, "GIRA EL MÓVIL", 48)
		_text(canvas, screen * 0.5 + Vector2(0, 65), "Juega en horizontal", 32)
		return
	if manual_paused:
		canvas.draw_rect(Rect2(Vector2.ZERO, screen), Color(0.03, 0.04, 0.05, 0.88))
		_text(canvas, screen * 0.5 + Vector2(0, -130), "PAUSA", 42)
		var labels := ["CONTINUAR", "REINICIAR NIVEL", "VOLVER AL MENÚ"]
		for index in 3:
			var rect := pause_rect(index)
			canvas.draw_rect(rect, INK)
			canvas.draw_rect(rect, GOLD, false, 3.0)
			_text(canvas, rect.get_center(), labels[index], 28)
		return
	_round_button(canvas, "pause", "PAUSA", 52)
	if can_fullscreen:
		_round_button(canvas, "fullscreen", "AMPLIAR", 52)
	if mode == "dialogue":
		var rect := Rect2(button_center("continue") - Vector2(170, 48), Vector2(340, 96))
		canvas.draw_rect(rect, INK)
		canvas.draw_rect(rect, GOLD, false, 3.0)
		_text(canvas, rect.get_center(), "CONTINUAR  >", 28)
		return
	if mode not in ["walk", "boat"]:
		return
	var center := joystick_center()
	canvas.draw_circle(center, JOY_RADIUS, INK)
	canvas.draw_arc(center, JOY_RADIUS, 0, TAU, 64, GOLD, 3.0, true)
	canvas.draw_line(center + Vector2(-65, 0), center + Vector2(65, 0), Color(1, 1, 1, 0.15), 2)
	canvas.draw_line(center + Vector2(0, -65), center + Vector2(0, 65), Color(1, 1, 1, 0.15), 2)
	canvas.draw_circle(center + stick * 68.0, 39, Color(0.85, 0.69, 0.4, 0.85))
	_text(canvas, center + Vector2(0, 132), "MOVER" if mode == "walk" else "NAVEGAR", 23)
	_round_button(canvas, "run", "CORRER" if mode == "walk" else "IMPULSO")
	_round_button(canvas, "interact", "ACCIÓN")
	if mode == "walk":
		_round_button(canvas, "throw", "PIEDRA")
		_text(canvas, button_center("throw") + Vector2(0, -90), "ARRASTRA Y SUELTA", 21)
		if aiming:
			var start := button_center("throw")
			canvas.draw_line(start, start + aim_direction * 110.0, GOLD, 5.0, true)

func _round_button(canvas: Control, which: String, label: String, radius: float = BUTTON_RADIUS) -> void:
	var center := button_center(which)
	canvas.draw_circle(center, radius, Color(0.35, 0.28, 0.16, 0.92) if fingers.values().has(which) else INK)
	canvas.draw_arc(center, radius, 0, TAU, 48, GOLD, 3.0, true)
	_text(canvas, center, label, 22 if radius < BUTTON_RADIUS else 25)

func _text(canvas: Control, center: Vector2, text: String, font_size: int) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_string(font, center + Vector2(-width * 0.5, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("fff0d3"))
