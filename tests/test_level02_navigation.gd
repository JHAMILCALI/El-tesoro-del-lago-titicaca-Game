extends SceneTree

var failures := 0
var cases := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_checks() -> void:
	var level := load("res://scenes/levels/LakeLevel02.tscn").instantiate() as Node2D
	root.add_child(level)
	level.set_process(false)
	var player := level.get_node("BoatPrototype/Boat") as CharacterBody2D
	player.set_physics_process(false)
	var enemy := level.get_node("Enemies/EnemyBoat1") as CharacterBody2D
	check(player.collision_mask & 1 != 0, "Player must collide with solid terrain")
	check(enemy.collision_mask & 1 != 0, "Spanish boat must collide with solid terrain")
	check(enemy.collision_layer == 0, "Enemy boats should keep distance-based capture")
	for old_island in level.get_node("BoatPrototype/Obstacles").get_children():
		check(old_island.collision_layer == 0, "Hidden prototype obstacle still collides")
	await physics_frame
	var bodies: Array[StaticBody2D] = []
	for name in ["IslandACollider", "IslandBCollider", "IslandCCollider"]:
		bodies.append(level.get_node("Islands/" + name))
	bodies.append(level.get_node("SanctuaryCollider"))
	for rock in level.get_node("Obstacles").get_children():
		bodies.append(rock as StaticBody2D)
	check(bodies.size() == 19, "Level 2 should contain four land bodies and 15 rocks")
	for body in bodies:
		check(body.collision_layer & 1 != 0, body.name + " must be solid")
		var outline := body.get_node("CollisionPolygon2D") as CollisionPolygon2D
		check(outline.polygon.size() >= 3, body.name + " needs an outline")
		var bounds := _global_bounds(outline)
		for boat in [player, enemy]:
			for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
				cases += 1
				var start := bounds.get_center()
				if direction == Vector2.RIGHT:
					start.x = bounds.position.x - 80.0
				elif direction == Vector2.LEFT:
					start.x = bounds.end.x + 80.0
				elif direction == Vector2.DOWN:
					start.y = bounds.position.y - 80.0
				else:
					start.y = bounds.end.y + 80.0
				var distance := (bounds.size.x if direction.x != 0 else bounds.size.y) + 160.0
				var collision := KinematicCollision2D.new()
				var moving_transform := Transform2D(0.0, start)
				var blocked: bool = boat.test_move(moving_transform, direction * distance, collision)
				check(blocked, boat.name + " crossed " + body.name + " from " + str(direction))
				if blocked:
					check(collision.get_collider() == body, boat.name + " hit another body before " + body.name)
	var island_bounds := _global_bounds(level.get_node("Islands/IslandACollider/CollisionPolygon2D"))
	var island_start := Vector2(island_bounds.position.x - 80.0, island_bounds.get_center().y)
	player.global_position = island_start
	player.rotation = 0.0
	for step in 35:
		player.velocity = Vector2.RIGHT * 500.0
		player._move_and_handle_obstacles()
		await physics_frame
	check(player.global_position.x < island_bounds.get_center().x, "Player crossed an island during actual movement")
	enemy.global_position = island_start
	enemy.rotation = 0.0
	for step in 35:
		enemy._move_toward(Vector2(island_bounds.end.x + 100.0, island_start.y), 500.0)
		await physics_frame
	check(enemy.global_position.x < island_bounds.get_center().x, "Spanish boat crossed an island during actual movement")
	var rock_bounds := _global_bounds(level.get_node("Obstacles/Rock1/CollisionPolygon2D"))
	enemy.global_position = Vector2(rock_bounds.position.x - 80.0, rock_bounds.get_center().y)
	enemy.rotation = 0.0
	for step in 35:
		enemy._move_toward(Vector2(rock_bounds.end.x + 100.0, enemy.global_position.y), 500.0)
		await physics_frame
	check(enemy.global_position.x < rock_bounds.get_center().x, "Spanish boat crossed a rock during actual movement")
	var finish := level.get_node("Areas/FinishArea") as Area2D
	check(finish.global_position.x < level.get_node("SanctuaryCollider").global_position.x, "Finish trigger must be on the water side of sanctuary")
	var shore_approach := Vector2(8620, -250)
	check(not player.test_move(Transform2D(0.0, shore_approach), finish.global_position - shore_approach), "Player cannot reach the sanctuary finish trigger from open water")
	var point_query := PhysicsPointQueryParameters2D.new()
	point_query.position = finish.global_position
	point_query.collision_mask = 1
	check(level.get_world_2d().direct_space_state.intersect_point(point_query).is_empty(), "Finish trigger sits inside solid land")
	level.queue_free()
	await process_frame
	print("LEVEL02_NAVIGATION_TESTS: ", cases, " sweep cases; ", failures, " failures")
	quit(1 if failures else 0)

func _global_bounds(outline: CollisionPolygon2D) -> Rect2:
	var first := outline.to_global(outline.polygon[0])
	var bounds := Rect2(first, Vector2.ZERO)
	for point in outline.polygon:
		bounds = bounds.expand(outline.to_global(point))
	return bounds
