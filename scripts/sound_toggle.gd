extends CanvasLayer
## Botón global de sonido: silencia o reactiva todo el audio (bus Master) en cualquier escena.
## También responde a la tecla M y lo usa el menú de pausa (ESC).

const GOLD := Color("e6ba70")
const INK := Color(0.08, 0.10, 0.11, 0.80)
const INK_HOVER := Color(0.35, 0.28, 0.16, 0.92)
const CREAM := Color("fff0d3")
const MUTED_MARK := Color("e8806f")
const DESKTOP_RADIUS := 18.0
const TOUCH_RADIUS := 52.0

var muted := false
var hovered := false
var surface: Control
var mobile_controls: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	mobile_controls = get_node_or_null("/root/MobileControls")
	surface = Control.new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.draw.connect(_draw_button)
	set_muted(false)

func _process(_delta: float) -> void:
	surface.queue_redraw()

func toggle() -> void:
	set_muted(not muted)

func set_muted(value: bool) -> void:
	muted = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), muted)
	surface.queue_redraw()

func _touch_layout() -> bool:
	return is_instance_valid(mobile_controls) and mobile_controls.enabled

func button_radius() -> float:
	return TOUCH_RADIUS if _touch_layout() else DESKTOP_RADIUS

func button_center() -> Vector2:
	var size := get_viewport().get_visible_rect().size
	if not _touch_layout():
		return Vector2(size.x - 146.0, 30.0)
	# Con controles táctiles se alinea con PAUSA y AMPLIAR; fuera de partida ocupa el lugar de PAUSA.
	var mode: String = mobile_controls.mode
	if mode.is_empty() or mode == "complete":
		return Vector2(size.x - 82.0, 68.0)
	return Vector2(size.x - (354.0 if mobile_controls.can_fullscreen else 218.0), 68.0)

func _hits(position: Vector2) -> bool:
	return position.distance_to(button_center()) <= button_radius() + 6.0

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_M:
			toggle()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed and _hits(event.position):
			toggle()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and _hits(event.position):
			# El toque emula un clic de ratón: se consume igual, pero solo se alterna una vez.
			if event.device != InputEvent.DEVICE_ID_EMULATION:
				toggle()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		hovered = _hits(event.position)

func _draw_button() -> void:
	var center := button_center()
	var radius := button_radius()
	surface.draw_circle(center, radius, INK_HOVER if hovered else INK)
	surface.draw_arc(center, radius, 0, TAU, 48, GOLD, 3.0, true)
	var unit := radius * 0.42
	var origin := center + Vector2(-0.25, 0.0) * unit
	var speaker := PackedVector2Array([
		Vector2(-1.0, -0.45), Vector2(-0.45, -0.45), Vector2(0.25, -1.0),
		Vector2(0.25, 1.0), Vector2(-0.45, 0.45), Vector2(-1.0, 0.45),
	])
	for i in speaker.size():
		speaker[i] = origin + speaker[i] * unit
	surface.draw_colored_polygon(speaker, CREAM)
	if muted:
		var width := maxf(3.0, radius * 0.09)
		surface.draw_line(origin + Vector2(0.65, -0.55) * unit, origin + Vector2(1.45, 0.55) * unit, MUTED_MARK, width, true)
		surface.draw_line(origin + Vector2(0.65, 0.55) * unit, origin + Vector2(1.45, -0.55) * unit, MUTED_MARK, width, true)
	else:
		var width := maxf(2.5, radius * 0.08)
		surface.draw_arc(origin + Vector2(0.35, 0.0) * unit, 0.75 * unit, -PI / 4.0, PI / 4.0, 12, CREAM, width, true)
		surface.draw_arc(origin + Vector2(0.35, 0.0) * unit, 1.3 * unit, -PI / 4.0, PI / 4.0, 12, CREAM, width, true)
