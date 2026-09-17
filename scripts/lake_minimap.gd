extends Control
class_name LakeMinimap

const WORLD_TOP_LEFT := Vector2(-700, -900)
const WORLD_SIZE := Vector2(9800, 2600)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var map_rect := Rect2(Vector2.ZERO, size)
	draw_rect(map_rect, Color("102f4b"), true)
	draw_rect(map_rect, Color(0.65, 0.85, 1.0, 0.85), false, 2.0)

	# Referencias fijas del lago para orientar las rutas del jugador.
	_draw_world_rect(Rect2(620, -300, 340, 380), Color("376b35"))
	_draw_world_rect(Rect2(1250, 220, 330, 350), Color("376b35"))
	_draw_world_rect(Rect2(1850, -600, 290, 320), Color("376b35"))
	_draw_world_rect(Rect2(3900, 280, 360, 360), Color("376b35"))
	_draw_world_rect(Rect2(6000, -700, 380, 410), Color("376b35"))
	_draw_world_rect(Rect2(8750, -700, 900, 900), Color("426c38"))

	var destination := get_tree().get_first_node_in_group("lake_destination") as Node2D
	if destination:
		var target := _to_map(destination.global_position)
		draw_circle(target, 7.0, Color("53e878"))
		draw_arc(target, 10.0, 0.0, TAU, 20, Color("d4ffe0"), 1.2)

	for enemy in get_tree().get_nodes_in_group("enemy_boat"):
		if enemy is Node2D and enemy.visible:
			draw_circle(_to_map(enemy.global_position), 4.5, Color("f04b4b"))

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var player_position := _to_map(player.global_position)
		draw_circle(player_position, 5.5, Color("ffd55b"))
		var heading := Vector2.from_angle(player.rotation) * 8.0
		draw_line(player_position, player_position + heading, Color.WHITE, 2.0)

func _draw_world_rect(world_rect: Rect2, color: Color) -> void:
	var top_left := _to_map(world_rect.position)
	var bottom_right := _to_map(world_rect.end)
	draw_rect(Rect2(top_left, bottom_right - top_left), color, true)

func _to_map(world_position: Vector2) -> Vector2:
	var ratio := (world_position - WORLD_TOP_LEFT) / WORLD_SIZE
	return Vector2(clampf(ratio.x, 0.0, 1.0) * size.x, clampf(ratio.y, 0.0, 1.0) * size.y)
