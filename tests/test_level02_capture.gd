extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_checks() -> void:
	check(change_scene_to_file("res://scenes/levels/LakeLevel02.tscn") == OK, "Could not load level 2")
	await process_frame
	await process_frame
	var level := current_scene
	check(level != null, "Level 2 is not the current scene")
	if level == null:
		quit(1)
		return
	level.set_process(false)
	var boat := level.get_node("BoatPrototype/Boat") as BoatPrototype
	var enemy := level.get_node("Enemies/EnemyBoat1") as EnemyBoat
	check(enemy.chase_speed > boat.normal_speed and enemy.chase_speed < boat.sprint_speed, "Spanish boat should catch normal rowing but allow a sprint escape")
	boat.set_physics_process(false)
	boat.global_position = Vector2(4000, -500)
	boat.rotation = 0.0
	enemy.set_physics_process(false)
	enemy.visible = true
	enemy.player = boat
	enemy.global_position = Vector2(4095, -500)
	check(enemy._is_head_on_contact(), "A Spanish boat touching the bow must capture")
	enemy.global_position = Vector2(4070, -430)
	check(not enemy._is_head_on_contact(), "A boat beside the player should not count as frontal capture")
	enemy._physics_process(1.0 / 60.0)
	check(not level.capture_in_progress, "Side contact restarted the level")
	enemy.global_position = Vector2(3930, -500)
	check(not enemy._is_head_on_contact(), "A boat behind the player should not count as frontal capture")
	enemy._physics_process(1.0 / 60.0)
	check(not level.capture_in_progress, "Rear contact restarted the level")
	enemy.global_position = Vector2(4097, -500)
	enemy._physics_process(1.0 / 60.0)
	check(level.capture_in_progress, "Front contact did not begin capture")
	check(not boat.can_move, "Player was not frozen after capture")
	var sequence := level.get_node_or_null("LakeCaptureSequence")
	check(sequence != null, "Capture did not start the sprite sequence")
	var started_at := Time.get_ticks_msec()
	var completed_at := [0]
	if sequence:
		sequence.finished.connect(func(): completed_at[0] = Time.get_ticks_msec())
	await create_timer(2.0).timeout
	check(current_scene == level, "Level restarted before the capture scene finished")
	if is_instance_valid(sequence):
		check(sequence.get_node("Screen/Stage/Ropes").modulate.a > 0.95, "Escorts did not secure the player boat")
		for sprite_name in ["Player", "Blocker", "LeftEscort", "RightEscort"]:
			var visual := sequence.get_node("Screen/Stage/" + sprite_name) as PlayerBoatVisual
			check(visual != null and visual.rowing_strength == 0.0, "Captured boats must stop rowing")
		check(sequence.get_node("Screen/Stage/LeftEscort").position.is_equal_approx(Vector2(-104, 36)), "Left escort did not close in")
		check(sequence.get_node("Screen/Stage/RightEscort").position.is_equal_approx(Vector2(104, 36)), "Right escort did not close in")
	await create_timer(2.3).timeout
	await process_frame
	check(completed_at[0] > 0 and absf(float(completed_at[0] - started_at) / 1000.0 - 4.0) < 0.2, "Capture sequence must last four seconds")
	check(current_scene != level and current_scene != null, "Capture did not reload the entire level")
	if current_scene != null:
		check(not current_scene.capture_in_progress, "New level retained capture state")
		check(not current_scene.enemies_activated, "New level retained enemy waves")
		check(current_scene.get_node("BoatPrototype/Boat") != boat, "New level reused the captured boat")
	print("LEVEL02_CAPTURE_TESTS: ", failures, " failures")
	quit(1 if failures else 0)
