extends Control

const MenuSkin = preload("res://scripts/menu_skin.gd")

@onready var mobile_controls: Node = get_node("/root/MobileControls")

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var boat_button: Button = $VBoxContainer/BoatButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var background_video: VideoStreamPlayer = $BackgroundVideo
@onready var background_music: AudioStreamPlayer = $BackgroundMusic

var level_01_scene: PackedScene = preload("res://scenes/levels/Level01_Convoy.tscn")
var boat_scene: PackedScene = preload("res://scenes/levels/LakeLevel02.tscn")

func _ready() -> void:
	MenuSkin.style_button(play_button, true)
	MenuSkin.style_button(boat_button)
	MenuSkin.style_button(quit_button)
	if background_video:
		background_video.finished.connect(_on_video_finished)
		background_video.play()
	if background_music:
		background_music.volume_db = linear_to_db(0.65)
		background_music.finished.connect(_on_music_finished)
		if not background_music.playing:
			background_music.play()
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
		play_button.grab_focus()
	if boat_button:
		boat_button.pressed.connect(_on_boat_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	mobile_controls.touch_mode_changed.connect(_apply_touch_layout)
	_apply_touch_layout()

func _apply_touch_layout() -> void:
	if not mobile_controls.enabled:
		return
	$VBoxContainer.offset_left = -410
	$VBoxContainer.offset_right = 410
	$VBoxContainer.offset_top = 18
	$VBoxContainer.offset_bottom = 230
	$MenuCard.offset_left = -460
	$MenuCard.offset_right = 460
	$MenuCard/CardKicker.offset_right = 900
	$MenuCard/CardKicker.add_theme_font_size_override("font_size", 23)
	$MenuCard/CardRule.offset_right = 886
	$MenuCard/CardFooter.offset_right = 890
	$MenuCard/CardFooter.offset_top = 270
	$MenuCard/CardFooter.offset_bottom = 292
	$MenuCard/CardFooter.add_theme_font_size_override("font_size", 16)
	$MenuCard.offset_bottom = 244
	$TitleTexture.offset_top = 0
	$TitleTexture.offset_bottom = 230
	for button in [play_button, boat_button]:
		button.custom_minimum_size.y = 82
		button.add_theme_font_size_override("font_size", 29)
	quit_button.hide()
	$SubtitleLabel.text = "Controles táctiles · Juega en horizontal"
	$SubtitleLabel.add_theme_font_size_override("font_size", 25)

func _on_video_finished() -> void:
	if background_video:
		background_video.play()

func _on_music_finished() -> void:
	if background_music:
		background_music.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_play_pressed()

func _on_play_pressed() -> void:
	print("[MainMenu] Cargando Nivel 1...")
	if level_01_scene:
		get_tree().change_scene_to_packed(level_01_scene)
	else:
		get_tree().change_scene_to_file("res://scenes/levels/Level01_Convoy.tscn")

func _on_boat_pressed() -> void:
	print("[MainMenu] Cargando Nivel 2: Travesía del Titicaca...")
	if boat_scene:
		get_tree().change_scene_to_packed(boat_scene)
	else:
		get_tree().change_scene_to_file("res://scenes/levels/LakeLevel02.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
