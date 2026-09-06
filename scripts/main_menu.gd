extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var boat_button: Button = $VBoxContainer/BoatButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if boat_button:
		boat_button.pressed.connect(_on_boat_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/Level01_Convoy.tscn")

func _on_boat_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/prototypes/BoatPrototype.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
