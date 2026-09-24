@tool
extends Control

enum MeterKind { ROWING, ALERT }

@export var meter_kind: MeterKind = MeterKind.ROWING:
	set(value):
		meter_kind = value
		if is_node_ready():
			set_ratio(1.0 if meter_kind == MeterKind.ROWING else 0.0, true)

var ratio := 1.0
var displayed_ratio := 1.0
var pulse_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	set_ratio(1.0 if meter_kind == MeterKind.ROWING else 0.0, true)

func set_ratio(value: float, immediately: bool = false) -> void:
	ratio = clampf(value, 0.0, 1.0)
	if immediately or Engine.is_editor_hint():
		displayed_ratio = ratio
	if is_node_ready():
		$Title.text = "REMO" if meter_kind == MeterKind.ROWING else "ALERTA"
		$Value.text = "%d%%" % roundi(ratio * 100.0)
		$Status.text = _status_text()
		$Value.modulate = _fill_color().lightened(0.3)
		$Status.modulate = Color("f1c680") if _is_urgent() else Color("c6b496")
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var previous := displayed_ratio
	displayed_ratio = move_toward(displayed_ratio, ratio, delta * 1.8)
	pulse_time += delta
	if previous != displayed_ratio or _is_urgent():
		queue_redraw()

func _status_text() -> String:
	if meter_kind == MeterKind.ROWING:
		if ratio <= 0.01:
			return "SIN FUERZAS · SUELTA SHIFT"
		if ratio <= 0.25:
			return "POCA RESISTENCIA · DESCANSA"
		return "RESISTENCIA · SHIFT PARA ACELERAR"
	if ratio >= 0.7:
		return "¡PELIGRO! · EVITA A LOS ESPAÑOLES"
	if ratio >= 0.3:
		return "LOS ESPAÑOLES TE BUSCAN"
	if ratio > 0.01:
		return "MANTÉN LA DISTANCIA"
	return "SIN RASTRO · AGUAS TRANQUILAS"

func _is_urgent() -> bool:
	return ratio <= 0.25 if meter_kind == MeterKind.ROWING else ratio >= 0.7

func _fill_color() -> Color:
	if meter_kind == MeterKind.ROWING:
		return Color("e4a44e") if ratio <= 0.25 else Color("37c9c2")
	if ratio >= 0.7:
		return Color("ef6349")
	return Color("ecac4b") if ratio >= 0.3 else Color("d79a52")

func _draw() -> void:
	var width := size.x
	var height := size.y
	if width < 80.0 or height < 60.0:
		return
	var corners := PackedVector2Array([Vector2(6, 1), Vector2(width - 7, 1), Vector2(width - 1, 7), Vector2(width - 1, height - 7), Vector2(width - 7, height - 1), Vector2(6, height - 1), Vector2(1, height - 7), Vector2(1, 7)])
	draw_rect(Rect2(4, 5, width - 4, height - 3), Color(0, 0, 0, 0.35))
	draw_colored_polygon(corners, Color("30231d"))
	draw_rect(Rect2(5, 5, width - 10, 23), Color("493322"))
	# Short grain strokes and stepped brass corners echo the wooden hulls.
	for index in 5:
		var grain_y := 31.0 + index * 10.0
		draw_line(Vector2(7, grain_y), Vector2(46, grain_y), Color("453026"), 1.0)
	var border := Color("ad8044")
	if _is_urgent():
		border = border.lerp(_fill_color(), 0.3 + 0.2 * sin(pulse_time * 4.0))
	var outline := corners.duplicate()
	outline.append(corners[0])
	draw_polyline(outline, border, 2.0)
	draw_line(Vector2(8, 5), Vector2(width - 9, 5), Color("d5ac62"), 1.0)
	for x in [8.0, width - 11.0]:
		for y in [9.0, height - 12.0]:
			draw_rect(Rect2(x, y, 3, 3), Color("e9c980"))
	_draw_emblem(Vector2(29, 43))
	var trough := Rect2(58, 34, width - 74, 21)
	draw_rect(trough.grow(1.0), Color("93703e"))
	draw_rect(trough, Color("100f15"))
	var track := Rect2(trough.position + Vector2(2, 2), trough.size - Vector2(4, 4))
	draw_rect(track, Color("262d31"))
	var fill_width := floorf(track.size.x * displayed_ratio)
	if fill_width > 0.0:
		var tint := _fill_color()
		draw_rect(Rect2(track.position, Vector2(fill_width, track.size.y)), tint)
		draw_rect(Rect2(track.position, Vector2(fill_width, 4)), tint.lightened(0.3))
		draw_rect(Rect2(track.position + Vector2(0, track.size.y - 3), Vector2(fill_width, 3)), tint.darkened(0.33))
		draw_rect(Rect2(track.position + Vector2(maxf(0.0, fill_width - 2), 1), Vector2(minf(2.0, fill_width), track.size.y - 2)), tint.lightened(0.5))
	for index in range(1, 10):
		var tick_x := roundf(track.position.x + track.size.x * index / 10.0)
		draw_line(Vector2(tick_x, track.position.y), Vector2(tick_x, track.end.y), Color(0.05, 0.1, 0.12, 0.28), 1.0)

func _draw_emblem(center: Vector2) -> void:
	var medallion := PackedVector2Array()
	for index in 8:
		medallion.append((center + Vector2.from_angle(PI / 8.0 + index * TAU / 8.0) * 19.0).round())
	draw_colored_polygon(medallion, Color("172c31") if meter_kind == MeterKind.ROWING else Color("44291f"))
	medallion.append(medallion[0])
	draw_polyline(medallion, Color("c59850"), 2.0)
	if meter_kind == MeterKind.ROWING:
		for direction in [-1.0, 1.0]:
			draw_line(center + Vector2(-8 * direction, -10), center + Vector2(8 * direction, 10), Color("efc982"), 3.0)
			draw_colored_polygon(PackedVector2Array([center + Vector2(3 * direction, 5), center + Vector2(7 * direction, 2), center + Vector2(12 * direction, 10), center + Vector2(8 * direction, 13)]), Color("f4d99c"))
	else:
		var eye := PackedVector2Array([center + Vector2(-12, 0), center + Vector2(-5, -6), center + Vector2(5, -6), center + Vector2(12, 0), center + Vector2(5, 6), center + Vector2(-5, 6), center + Vector2(-12, 0)])
		draw_polyline(eye, Color("f4d99c"), 2.0)
		draw_rect(Rect2(center - Vector2(3, 3), Vector2(6, 6)), _fill_color())
		draw_line(center + Vector2(0, -13), center + Vector2(0, -9), Color("efc982"), 2.0)
