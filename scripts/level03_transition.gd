extends Control

const MenuSkin = preload("res://scripts/menu_skin.gd")

@onready var menu_button: Button = $Card/MenuButton

func _ready() -> void:
	MenuSkin.style_button(menu_button, true)
	menu_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn"))
	menu_button.grab_focus()
