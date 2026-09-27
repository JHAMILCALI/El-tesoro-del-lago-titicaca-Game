extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_checks() -> void:
	# JUGAR lleva a la cinemática, no directamente al nivel.
	check(change_scene_to_file("res://scenes/main/MainMenu.tscn") == OK, "Could not load main menu")
	await process_frame
	await process_frame
	var menu := current_scene
	menu._on_play_pressed()
	await process_frame
	await process_frame
	var intro := current_scene
	check(intro != null and intro.scene_file_path == "res://scenes/levels/Level01Intro.tscn", "Play button did not open the level 1 cinematic")
	if intro == null:
		quit(1)
		return

	var video: VideoStreamPlayer = intro.get_node("Video")
	var music: AudioStreamPlayer = intro.get_node("Music")
	var skip_button: Button = intro.get_node("SkipButton")
	check(video.stream != null, "Cinematic has no video")
	check(video.is_playing(), "Cinematic video did not start")
	check(music.stream is AudioStreamMP3 and music.playing, "Cinematic is missing the level 1 background music")
	check(music.stream != null and music.stream.resource_path == "res://assets/audio/Ambient Background Version.mp3", "Cinematic does not use the level 1 music")
	check(skip_button.visible and skip_button.text != "", "Cinematic has no skip button")

	# Saltar lleva al nivel 1 sin volver a ver el vídeo.
	skip_button.pressed.emit()
	await create_timer(1.6).timeout
	var level := current_scene
	check(level != null and level.scene_file_path == "res://scenes/levels/Level01_Convoy.tscn", "Skipping did not open level 1")
	if level != null:
		var background_music: AudioStreamPlayer = level.get_node("BackgroundMusic")
		check(background_music.playing, "Level 1 music did not start after the cinematic")

	print("LEVEL01_INTRO_TESTS: ", failures, " failures")
	quit(1 if failures else 0)
