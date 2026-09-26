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
	var left: SpanishPatrol = level.get_node("TreasureGuardLeft")
	var right: SpanishPatrol = level.get_node("TreasureGuardRight")
	var pasco: Pasco = level.get_node("Pasco")
	var house: HouseInterior = level.get_node("HouseInterior")
	for patrol in level._all_patrols():
		patrol.set_physics_process(false)
	level.story_state = level.StoryState.TREASURE_QUEST_ACTIVE
	check(level._active_treasure_guards() == 2, "House must start with two active guards")
	check(left.global_position.distance_to(house.global_position) < 250.0, "Left guard is too far from the house")
	check(right.global_position.distance_to(house.global_position) < 250.0, "Right guard is too far from the house")

	left.knock_out(20.0)
	check(level._active_treasure_guards() == 1, "One guard must remain active")
	level._on_house_enter_requested()
	check(pasco.global_position.is_equal_approx(house.get_interior_spawn_position()), "Entry must place Pasco inside before capture")
	level._on_treasure_requested()
	check(not level.has_treasure and house.treasure_available, "One unconscious guard must not unlock the treasure")
	await process_frame
	check(level.capture_in_progress, "The remaining guard must capture Pasco inside")
	check(pasco.global_position.distance_to(house.get_interior_spawn_position()) < 80.0, "Capture must start inside the house")
	await create_timer(4.2).timeout
	await process_frame
	check(not level.capture_in_progress, "House capture did not finish")
	check(pasco.global_position.is_equal_approx(level.checkpoint_house.global_position), "House capture did not return to the checkpoint")

	var first_stone: Stone = load("res://scenes/objects/Stone.tscn").instantiate()
	level.add_child(first_stone)
	first_stone.global_position = left.global_position
	check(first_stone._try_direct_patrol_hit(), "A stone must knock out the first house guard")
	var second_stone: Stone = load("res://scenes/objects/Stone.tscn").instantiate()
	level.add_child(second_stone)
	second_stone.global_position = left.global_position
	check(not second_stone._try_direct_patrol_hit(), "Stones must pass an unconscious guard")
	second_stone.global_position = right.global_position
	check(second_stone._try_direct_patrol_hit(), "A stone must knock out the second house guard")
	check(level._active_treasure_guards() == 0, "Both house guards must be unconscious")
	level._on_house_enter_requested()
	check(level.house_entry_secure and not level.capture_in_progress, "Entering with both guards down must be safe")
	check(pasco.global_position.is_equal_approx(house.get_interior_spawn_position()), "Safe entry did not reach the interior")
	check(left.unconscious_held and right.unconscious_held, "House guards must stay down while Pasco is inside")
	left._process_unconscious(15.0)
	right._process_unconscious(15.0)
	check(level._active_treasure_guards() == 0, "House guards woke up before Pasco could collect the treasure")
	level._on_treasure_requested()
	check(level.has_treasure and not house.treasure_available, "Treasure should be collected after both guards fall")
	level._on_house_exit_requested()
	check(pasco.global_position.is_equal_approx(house.get_exterior_spawn_position()), "Pasco must be able to leave the house")
	check(level._active_treasure_guards() == 0, "House guards must still be down when Pasco leaves")
	check(not left.unconscious_held and not right.unconscious_held, "Guard timers must resume after Pasco leaves")
	check(left.unconscious_time_remaining >= 8.0 and right.unconscious_time_remaining >= 8.0, "Pasco needs an escape window after leaving")
	print("HOUSE_GUARDS_TESTS: ", failures, " failures")
	quit(1 if failures else 0)
