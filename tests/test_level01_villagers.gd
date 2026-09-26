extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_checks() -> void:
	check(change_scene_to_file("res://scenes/levels/Level01_Convoy.tscn") == OK, "Could not load level 1")
	await process_frame
	await process_frame
	var level := current_scene
	if level == null:
		quit(1)
		return
	var villagers := get_nodes_in_group("local_villagers")
	check(villagers.size() >= 12, "The village needs people walking along the path")
	var appearances := {}
	for node in villagers:
		var villager: LocalVillager = node
		check(villager.appearance != null and villager.sprite.texture != null, "A villager has no sprite")
		check(not villager.is_in_group("enemies"), "Civilians must not be enemies")
		check(villager.get_node_or_null("CollisionShape2D") == null, "Civilians must not block movement")
		check(_on_path(villager), "A villager is outside the main path")
		check(villager.route_start.distance_to(villager.route_end) >= 350.0, "A villager route is too short")
		check(villager.appearance.get_width() % LocalVillager.WALK_FRAMES == 0, "A walking sprite sheet has uneven frames")
		appearances[villager.appearance.resource_path] = true
	check(appearances.size() == 4, "The four distinct civilian sprites must be present")

	var amauta: LocalVillager = level.get_node("Level01Village/LocalVillagers/AmautaWest")
	var stone: Stone = load("res://scenes/objects/Stone.tscn").instantiate()
	stone.set_process(false)
	level.add_child(stone)
	stone.global_position = amauta.global_position
	check(not stone._try_direct_patrol_hit(), "A stone should not hit a civilian")
	check(is_instance_valid(amauta) and amauta.is_inside_tree(), "A civilian disappeared after a stone passed")
	stone.queue_free()

	var patrol: SpanishPatrol = level.get_node("SpanishPatrol1")
	patrol.set_physics_process(false)
	var original_position := patrol.global_position
	var mother: LocalVillager = level.get_node("Level01Village/LocalVillagers/MotherWest")
	mother.set_physics_process(false)
	patrol.global_position = mother.global_position + Vector2(70.0, 0.0)
	var starting_distance := mother.global_position.distance_to(patrol.global_position)
	mother._physics_process(1.0)
	check(mother.global_position.distance_to(patrol.global_position) > starting_distance, "A civilian did not move away from a Spanish patrol")
	check(_on_path(mother), "Avoiding a patrol must keep civilians on the path")
	patrol.global_position = original_position

	var weaver: LocalVillager = level.get_node("Level01Village/LocalVillagers/WeaverWest")
	var start_position: Vector2 = weaver.global_position
	var seen_frames := {}
	for node in villagers:
		node.set_physics_process(false)
	for tick in range(600):
		for node in villagers:
			node._physics_process(1.0 / 60.0)
		seen_frames[weaver.current_walk_frame] = true
	check(weaver.global_position.distance_to(start_position) > 150.0, "Village workers must walk substantial distances")
	check(seen_frames.size() == LocalVillager.WALK_FRAMES, "The walking animation did not play all four frames")
	for node in villagers:
		check(_on_path(node), "A civilian left the path")
		check(_within_route(node), "A civilian walked beyond their route")
	print("LEVEL01_VILLAGERS_TESTS: ", failures, " failures")
	quit(1 if failures else 0)

func _on_path(villager: LocalVillager) -> bool:
	return villager.global_position.x >= 50.0 and villager.global_position.x <= 3300.0 and villager.global_position.y >= 260.0 and villager.global_position.y <= 460.0

func _within_route(villager: LocalVillager) -> bool:
	var left := minf(villager.route_start.x, villager.route_end.x)
	var right := maxf(villager.route_start.x, villager.route_end.x)
	return villager.global_position.x >= left - 1.0 and villager.global_position.x <= right + 1.0
