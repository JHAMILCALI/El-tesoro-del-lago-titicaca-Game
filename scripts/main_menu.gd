extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var boat_button: Button = $VBoxContainer/BoatButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var background_video: VideoStreamPlayer = $BackgroundVideo

var level_01_scene: PackedScene = preload("res://scenes/levels/Level01_Convoy.tscn")
var boat_scene: PackedScene = preload("res://scenes/prototypes/BoatPrototype.tscn")

func _ready() -> void:
	if background_video:
		background_video.finished.connect(_on_video_finished)
		background_video.play()
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
		play_button.grab_focus()
	if boat_button:
		boat_button.pressed.connect(_on_boat_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_video_finished() -> void:
	if background_video:
		background_video.play()

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
	print("[MainMenu] Cargando Prototipo de Barca...")
	if boat_scene:
		get_tree().change_scene_to_packed(boat_scene)
	else:
		get_tree().change_scene_to_file("res://scenes/prototypes/BoatPrototype.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
