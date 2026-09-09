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
@onready var detection_container: Control = $Control/DetectionContainer
@onready var detection_bar_label: Label = $Control/DetectionContainer/DetectionBarLabel
@onready var stone_count_label: Label = $Control/StoneCountPanel/StoneCountLabel

func _ready() -> void:
	add_to_group("hud")
	if interaction_prompt:
		interaction_prompt.visible = false
	if notification_label:
		notification_label.visible = false
	if alpha_complete_panel:
		alpha_complete_panel.visible = false
	if detection_container:
		detection_container.visible = false

	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func update_objective(text: String) -> void:
	if objective_label:
		objective_label.text = "OBJETIVO:\n" + text

func update_stone_count(count: int) -> void:
	if stone_count_label:
		stone_count_label.text = "PIEDRAS: " + str(count) + "  [Q]"

func update_detection_progress(ratio: float) -> void:
	if not detection_container or not detection_bar_label:
		return

	if ratio <= 0.0:
		detection_container.visible = false
	else:
		detection_container.visible = true
		var total_blocks := 10
		var filled_blocks := int(round(ratio * total_blocks))
		filled_blocks = clampi(filled_blocks, 0, total_blocks)
		var bar_str := "["
		for i in range(total_blocks):
			if i < filled_blocks:
				bar_str += "█"
			else:
				bar_str += "░"
		bar_str += "]"
		detection_bar_label.text = bar_str

func show_interaction_prompt(prompt_text: String = "[E] HABLAR") -> void:
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
			if notification_label and notification_label.text == message:
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
