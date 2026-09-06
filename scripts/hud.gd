extends CanvasLayer
class_name HUD

signal restart_requested
signal menu_requested

@onready var objective_label: Label = $Control/ObjectiveLabel
@onready var interaction_prompt: Label = $Control/InteractionPrompt
@onready var notification_label: Label = $Control/NotificationLabel
@onready var alpha_complete_panel: Panel = $Control/AlphaCompletePanel
@onready var restart_button: Button = $Control/AlphaCompletePanel/VBoxContainer/RestartButton
@onready var menu_button: Button = $Control/AlphaCompletePanel/VBoxContainer/MenuButton

var notification_timer: SceneTreeTimer = null

func _ready() -> void:
	add_to_group("hud")
	if interaction_prompt:
		interaction_prompt.visible = false
	if notification_label:
		notification_label.visible = false
	if alpha_complete_panel:
		alpha_complete_panel.visible = false

	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func update_objective(text: String) -> void:
	if objective_label:
		objective_label.text = "Objetivo:\n" + text

func show_interaction_prompt(prompt_text: String = "[E] Interactuar") -> void:
	if interaction_prompt:
		interaction_prompt.text = prompt_text
		interaction_prompt.visible = true

func hide_interaction_prompt() -> void:
	if interaction_prompt:
		interaction_prompt.visible = false

func show_temporary_notification(message: String, duration: float = 2.0) -> void:
	if notification_label:
		notification_label.text = message
		notification_label.visible = true
		get_tree().create_timer(duration).timeout.connect(func():
			if notification_label:
				notification_label.visible = false
		)

func show_alpha_complete() -> void:
	if alpha_complete_panel:
		alpha_complete_panel.visible = true
	var pasco = get_tree().get_first_node_in_group("player")
	if pasco and pasco.has_method("set_movement_enabled"):
		pasco.set_movement_enabled(false)

func _on_restart_pressed() -> void:
	restart_requested.emit()

func _on_menu_pressed() -> void:
	menu_requested.emit()
