extends Control
class_name LakeMinimap

# The lake is much wider than it is tall. These bounds keep both shores and
# the sanctuary visible while using the full height of the chart.
const WORLD_RECT := Rect2(-750.0, -950.0, 10500.0, 1850.0)
const WATER := Color("123a53")
const WATER_LIGHT := Color("245b72")
const SHORE := Color("697b46")
const SAND := Color("c9a86d")
const ISLAND := Color("3f7852")
const ROCK := Color("b9b1a2")
const PLAYER := Color("f8d782")
const ENEMY := Color("ef7469")
const DESTINATION := Color("76dfc2")

var redraw_timer := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	redraw_timer += delta
	if redraw_timer >= 0.1:
		redraw_timer = 0.0
		queue_redraw()

func _draw() -> void:
	if size.x < 80.0 or size.y < 70.0:
		return
	var frame := Rect2(Vector2.ZERO, size)
	var water := frame.grow(-4.0)
	draw_rect(frame, Color("101d27"))
	draw_rect(water, WATER)
	_draw_water_details(water)
	_draw_departure_shore()
	_draw_islands()
	_draw_rocks()
	_draw_destination()
	_draw_enemies()
	_draw_player()
	draw_rect(frame.grow(-0.5), SAND, false, 1.5)
	draw_rect(water, Color("5e91a4"), false, 1.0)

func _draw_water_details(water: Rect2) -> void:
	for index in 4:
		var y := water.position.y + water.size.y * (0.18 + index * 0.22)
		draw_rect(Rect2(water.position.x + 1.0, y, water.size.x - 2.0, 9.0), Color(0.2, 0.55, 0.65, 0.07))
	for column in 1 + int(water.size.x / 42.0):
		for row in 1 + int(water.size.y / 28.0):
			var x := water.position.x + 9.0 + column * 42.0 + float(row % 2) * 17.0
			var y := water.position.y + 10.0 + row * 28.0
			if x < water.end.x - 12.0 and y < water.end.y - 7.0:
				draw_line(Vector2(x, y), Vector2(x + 9.0, y), Color(WATER_LIGHT, 0.38), 1.0)
				draw_line(Vector2(x + 12.0, y + 3.0), Vector2(x + 16.0, y + 3.0), Color(WATER_LIGHT, 0.25), 1.0)

func _draw_departure_shore() -> void:
	var coast := PackedVector2Array([
		_to_map(Vector2(-750, 160)),
		_to_map(Vector2(350, 160)),
		_to_map(Vector2(610, 290)),
		_to_map(Vector2(680, 620)),
		_to_map(Vector2(680, 900)),
		_to_map(Vector2(-750, 900))
	])
	draw_colored_polygon(coast, SHORE)
	draw_polyline(PackedVector2Array([coast[1], coast[2], coast[3], coast[4]]), SAND, 1.5, true)
	for world_position in [Vector2(-220, 360), Vector2(180, 520), Vector2(470, 705)]:
		draw_circle(_to_map(world_position), 1.5, Color("8ea868"))

func _draw_islands() -> void:
	for island in get_tree().get_nodes_in_group("lake_islands"):
		if not island is Node2D or not island.is_visible_in_tree():
			continue
		var collision := island.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
		if collision == null or collision.polygon.size() < 3:
			continue
		var points := PackedVector2Array()
		for vertex in collision.polygon:
			points.append(_to_map(collision.to_global(vertex)))
		draw_colored_polygon(points, ISLAND)
		var min_x := points[0].x
		var max_x := points[0].x
		var center := Vector2.ZERO
		for point in points:
			min_x = minf(min_x, point.x)
			max_x = maxf(max_x, point.x)
			center += point
		center /= points.size()
		points.append(points[0])
		draw_polyline(points, SAND, 1.2, true)
		if max_x - min_x < 9.0:
			draw_circle(center, 4.2, SAND)
			draw_circle(center, 3.0, ISLAND)
			draw_circle(center + Vector2(-1.0, -1.0), 1.0, Color("a9bd82"))

func _draw_rocks() -> void:
	for rock in get_tree().get_nodes_in_group("lake_rocks"):
		if not rock is Node2D or not rock.is_visible_in_tree():
			continue
		var center := _to_map(rock.global_position)
		draw_circle(center, 3.0, Color("394754"))
		draw_circle(center, 2.1, ROCK)
		draw_line(center + Vector2(-1.0, -1.0), center, Color("f2e1c3"), 1.0)

func _draw_destination() -> void:
	var destination := get_tree().get_first_node_in_group("lake_destination") as Node2D
	if destination == null:
		return
	var center := _to_map(destination.global_position)
	draw_circle(center, 10.0, Color("13392f"))
	draw_arc(center, 8.0, 0.0, TAU, 24, DESTINATION, 2.0, true)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -5), center + Vector2(5, 0),
		center + Vector2(0, 5), center + Vector2(-5, 0)
	]), Color("f8dda0"))
	draw_circle(center, 1.6, Color("2d7559"))

func _draw_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy_boat"):
		if not enemy is Node2D or not enemy.is_visible_in_tree():
			continue
		var center := _to_map(enemy.global_position)
		draw_circle(center, 5.0, Color("432b35"))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(5, 0), center + Vector2(-3, -3.5), center + Vector2(-3, 3.5)
		]), ENEMY)

func _draw_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var center := _to_map(player.global_position)
	var forward := Vector2.from_angle(player.rotation)
	var side := forward.orthogonal()
	draw_circle(center, 8.0, Color("1e3441"))
	draw_arc(center, 8.0, 0.0, TAU, 24, Color("fff0bd"), 1.1, true)
	draw_colored_polygon(PackedVector2Array([
		center + forward * 7.0,
		center - forward * 5.0 + side * 4.0,
		center - forward * 5.0 - side * 4.0
	]), PLAYER)
	draw_line(center, center + forward * 5.0, Color("5a3c2b"), 1.2)

func _to_map(world_position: Vector2) -> Vector2:
	var inset := Rect2(Vector2(13.0, 13.0), size - Vector2(26.0, 26.0))
	var ratio := (world_position - WORLD_RECT.position) / WORLD_RECT.size
	return inset.position + Vector2(clampf(ratio.x, 0.0, 1.0), clampf(ratio.y, 0.0, 1.0)) * inset.size
