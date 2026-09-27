extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_checks() -> void:
	check(change_scene_to_file("res://scenes/levels/LakeLevel02.tscn") == OK, "Could not load lake level")
	await process_frame
	await process_frame
	var lake := current_scene
	if lake == null:
		quit(1)
		return
	var boat: Node2D = lake.get_node("BoatPrototype/Boat")
	lake._on_finish_area_body_entered(boat)
	await process_frame
	await process_frame
	var cinematic := current_scene
	check(cinematic != null and cinematic.scene_file_path == "res://scenes/levels/FinalCinematic.tscn", "Reaching the sanctuary did not open the final cinematic")
	if cinematic == null or cinematic.scene_file_path != "res://scenes/levels/FinalCinematic.tscn":
		quit(1)
		return
	var video: VideoStreamPlayer = cinematic.get_node("Video")
	var skip_button: Button = cinematic.get_node("SkipButton")
	check(video.stream is VideoStreamTheora, "Final cinematic does not use a Godot-compatible video")
	check(video.stream.resource_path == "res://assets/videos/final.ogv", "Final cinematic does not use the supplied video")
	check(video.is_playing(), "Final cinematic did not start playing")
	check(skip_button.visible and skip_button.text == "SALTAR CINEMÁTICA", "Final cinematic has no visible skip button")
	skip_button.pressed.emit()
	await create_timer(0.5).timeout
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/levels/Level03_Transition.tscn", "Skipping the final cinematic did not open the ending")
	check(change_scene_to_file("res://scenes/levels/FinalCinematic.tscn") == OK, "Could not replay final cinematic")
	await process_frame
	await process_frame
	current_scene.get_node("Video").finished.emit()
	await create_timer(0.5).timeout
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/levels/Level03_Transition.tscn", "Finishing the final cinematic did not open the ending")
	print("FINAL_CINEMATIC_TESTS: ", failures, " failures")
	quit(1 if failures else 0)
