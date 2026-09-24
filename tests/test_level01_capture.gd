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
	check(level != null, "Level 1 is not the current scene")
	if level == null:
		quit(1)
		return
	var pasco := level.get_node("Pasco")
	var start_checkpoint: Node2D = level.get_node("Checkpoints/StartCheckpoint")
	var escort_checkpoint: Node2D = level.get_node("Checkpoints/CheckpointEscort")
	var huita := level.get_node("Huita")
	var patrol := level.get_node("SpanishPatrol1")
	patrol.set_physics_process(false)
	pasco.global_position = start_checkpoint.global_position + Vector2(200, 0)
	var capture_position: Vector2 = pasco.global_position
	level._on_player_captured()
	level._on_player_captured()
	check(level.capture_in_progress, "Capture was not started")
	check(not pasco.can_move, "Pasco can move during capture")
	check(pasco.global_position.is_equal_approx(capture_position), "Pasco teleported before the sequence finished")
	check(level.get_node_or_null("Level01CaptureSequence") != null, "Capture sprite sequence was not added")
	await create_timer(1.55).timeout
	var sequence := level.get_node_or_null("Level01CaptureSequence")
	check(sequence != null, "Capture sequence ended too early")
	if sequence:
		check(sequence.get_node("Screen/Stage/Captured").modulate.a > 0.95, "Detained Pasco sprite is not visible")
		check(sequence.get_node("Screen/Stage/Title").text == "¡CAPTURADO!", "Capture title did not change")
	check(pasco.global_position.is_equal_approx(capture_position), "Pasco returned before four seconds")
	await create_timer(2.65).timeout
	await process_frame
	check(not level.capture_in_progress, "Capture remained active after the sequence")
	check(pasco.global_position.is_equal_approx(start_checkpoint.global_position), "Initial capture did not return to the start checkpoint")
	check(pasco.can_move, "Pasco remained frozen at checkpoint")
	check(level.get_node_or_null("Level01CaptureSequence") == null, "Capture sequence was not removed")

	await create_timer(1.25).timeout
	level.story_state = 8
	level.last_checkpoint_pos = escort_checkpoint.global_position
	pasco.global_position = escort_checkpoint.global_position + Vector2(280, 0)
	level._on_player_captured()
	check(level.capture_in_progress, "Second capture did not begin")
	await create_timer(4.2).timeout
	await process_frame
	check(pasco.global_position.is_equal_approx(escort_checkpoint.global_position), "Escort capture did not use the latest checkpoint")
	check(huita.global_position.is_equal_approx(escort_checkpoint.global_position + Vector2(-40, 0)), "Huita did not return with Pasco")
	check(huita.is_following, "Huita stopped following after checkpoint return")
	check(pasco.can_move and not level.capture_in_progress, "Controls were not restored after escort capture")
	print("LEVEL01_CAPTURE_TESTS: ", failures, " failures")
	quit(1 if failures else 0)
