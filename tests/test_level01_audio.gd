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
	for patrol in level._all_patrols():
		patrol.set_physics_process(false)

	var pasco: Pasco = level.get_node("Pasco")
	var footstep_audio: AudioStreamPlayer = pasco.get_node("FootstepAudio")
	var throw_audio: AudioStreamPlayer = pasco.get_node("ThrowAudio")
	check(footstep_audio != null, "Pasco has no footstep audio player")
	check(throw_audio.stream != null, "Pasco has no stone throw sound")

	var main_path: Control = level.get_node("Terrain/MainPath")
	pasco.global_position = main_path.get_global_rect().get_center()
	pasco._update_footstep_audio(true, false)
	check(pasco.current_footstep_surface == &"dirt", "The dirt path did not select dirt footsteps")
	check(footstep_audio.stream is AudioStreamMP3 and (footstep_audio.stream as AudioStreamMP3).loop, "Dirt footsteps are not looped")

	pasco.global_position = Vector2(500, 100)
	pasco._update_footstep_audio(true, true)
	check(pasco.current_footstep_surface == &"grass", "The grass did not select grass footsteps")
	check(is_equal_approx(footstep_audio.pitch_scale, 1.12), "Running did not accelerate the footstep cadence")
	pasco._update_footstep_audio(false, false)
	check(not footstep_audio.playing, "Footsteps continued after Pasco stopped")

	throw_audio.play()
	check(throw_audio.playing, "The stone throw sound could not play")
	throw_audio.stop()

	var stone: Stone = load("res://scenes/objects/Stone.tscn").instantiate()
	level.add_child(stone)
	stone.global_position = pasco.global_position
	stone._land()
	await process_frame
	var impact_audio := _find_sound(level, &"stone_impact")
	check(impact_audio != null, "Landing a stone did not create its impact sound")

	var pickup: PickableStone = load("res://scenes/objects/PickableStone.tscn").instantiate()
	level.add_child(pickup)
	pickup.global_position = pasco.global_position
	var previous_stones := pasco.stone_count
	pickup._on_body_entered(pasco)
	await process_frame
	check(pasco.stone_count == previous_stones + 1, "The test stone was not collected")
	var pickup_audio := _find_sound(level, &"stone_pickup")
	check(pickup_audio != null, "Collecting a stone did not create its pickup sound")

	print("LEVEL01_AUDIO_TESTS: ", failures, " failures")
	quit(1 if failures else 0)

func _find_sound(parent: Node, kind: StringName) -> AudioStreamPlayer2D:
	for child in parent.get_children():
		if child is AudioStreamPlayer2D and child.get_meta("sound_kind", &"") == kind:
			return child
	return null
