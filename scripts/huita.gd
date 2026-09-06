extends Area2D
class_name Huita

signal interaction_requested

var is_player_near: bool = false
var has_talked: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if is_player_near and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interaction_requested.emit()

func _on_body_entered(body: Node2D) -> void:
	if body is Pasco:
		is_player_near = true
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_interaction_prompt"):
			hud.show_interaction_prompt("[E] Interactuar")

func _on_body_exited(body: Node2D) -> void:
	if body is Pasco:
		is_player_near = false
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("hide_interaction_prompt"):
			hud.hide_interaction_prompt()
