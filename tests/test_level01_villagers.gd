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
	check(villagers.size() >= 12, "The village needs people along both sides of the path")
	var appearances := {}
	for node in villagers:
		var villager: LocalVillager = node
		check(villager.appearance != null and villager.sprite.texture != null, "A villager has no sprite")
		check(not villager.is_in_group("enemies"), "Civilians must not be enemies")
		check(villager.get_node_or_null("CollisionShape2D") == null, "Civilians must not block movement")
		check(_on_grass(villager), "A villager entered the main path")
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
	patrol.global_position = Vector2(mother.global_position.x, 260.0)
	var starting_distance := mother.global_position.distance_to(patrol.global_position)
	mother._physics_process(1.0)
	check(mother.global_position.distance_to(patrol.global_position) > starting_distance, "A civilian did not move away from a Spanish patrol")
	check(_on_grass(mother), "Avoiding a patrol must not push civilians onto the path")
	patrol.global_position = original_position

	var start_position: Vector2 = level.get_node("Level01Village/LocalVillagers/WeaverWest").global_position
	for node in villagers:
		node.set_physics_process(false)
	for tick in range(420):
		for node in villagers:
			node._physics_process(1.0 / 60.0)
	check(level.get_node("Level01Village/LocalVillagers/WeaverWest").global_position.distance_to(start_position) > 3.0, "Village workers never walk between their tasks")
	for node in villagers:
		check(_on_grass(node), "A civilian left the grass")
	print("LEVEL01_VILLAGERS_TESTS: ", failures, " failures")
	quit(1 if failures else 0)

func _on_grass(villager: LocalVillager) -> bool:
	if villager.grass_side == LocalVillager.GrassSide.NORTH:
		return villager.global_position.y >= 35.0 and villager.global_position.y <= 95.0
	return villager.global_position.y >= 585.0 and villager.global_position.y <= 655.0
