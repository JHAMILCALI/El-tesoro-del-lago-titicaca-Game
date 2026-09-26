extends CanvasLayer
class_name HUD

@onready var mobile_controls: Node = get_node("/root/MobileControls")

const StatusMeter = preload("res://scripts/lake_status_meter.gd")
const HudNoticeScript = preload("res://scripts/hud_notice.gd")
const MenuSkin = preload("res://scripts/menu_skin.gd")

signal restart_requested
signal menu_requested
signal next_level_requested

@onready var objective_label: Label = $Control/ObjectivePanel/ObjectiveLabel
@onready var interaction_prompt: Label = $Control/InteractionPrompt
@onready var notification_panel: HudNoticeScript = $Control/NotificationPanel
@onready var alpha_complete_panel: Panel = $Control/AlphaCompletePanel
@onready var complete_backdrop: ColorRect = $Control/CompleteBackdrop
@onready var next_level_button: Button = $Control/AlphaCompletePanel/VBoxContainer/NextLevelButton
@onready var restart_button: Button = $Control/AlphaCompletePanel/VBoxContainer/RestartButton
@onready var menu_button: Button = $Control/AlphaCompletePanel/VBoxContainer/MenuButton
@onready var detection_container: Control = $Control/DetectionContainer
@onready var detection_bar_label: Label = $Control/DetectionContainer/DetectionBarLabel
@onready var stone_count_label: Label = $Control/StoneCountPanel/StoneCountLabel
@onready var rowing_container: StatusMeter = $Control/RowingContainer
@onready var alert_container: StatusMeter = $Control/AlertContainer
@onready var speed_label: Label = $Control/SpeedPanel/SpeedLabel
@onready var minimap_panel: Control = $Control/MiniMapPanel

func _ready() -> void:
	add_to_group("hud")
	var control_node = get_node_or_null("Control")
	if control_node is Control:
		control_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child in control_node.get_children():
			if child is Control and child not in [alpha_complete_panel, complete_backdrop]:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MenuSkin.style_button(next_level_button, true)
	MenuSkin.style_button(restart_button)
	MenuSkin.style_button(menu_button)

	if interaction_prompt:
		interaction_prompt.visible = false
	if notification_panel:
		notification_panel.visible = false
	if alpha_complete_panel:
		alpha_complete_panel.visible = false
	complete_backdrop.visible = false
	if detection_container:
		detection_container.visible = false
	if rowing_container:
		rowing_container.visible = false
	if alert_container:
		alert_container.visible = false
	if speed_label:
		speed_label.visible = false
	if minimap_panel:
		minimap_panel.visible = false

	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if next_level_button:
		next_level_button.pressed.connect(_on_next_level_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	mobile_controls.touch_mode_changed.connect(_apply_touch_layout)
	get_viewport().size_changed.connect(_apply_touch_layout)
	_apply_touch_layout()

func _apply_touch_layout() -> void:
	if not mobile_controls.enabled:
		return
	$Control/PauseHelpLabel.hide()
	var objective: Control = $Control/ObjectivePanel
	objective.position = Vector2(24, 20)
	objective.size = Vector2(530, 112)
	objective_label.position = Vector2(16, 38)
	objective_label.size = Vector2(498, 70)
	objective_label.add_theme_font_size_override("font_size", 25)
	$Control/ObjectivePanel/ObjectiveTitle.add_theme_font_size_override("font_size", 20)
	$Control/ObjectivePanel/ObjectiveRule.size.x = 500
	$Control/StoneCountPanel.position = Vector2(576, 20)
	$Control/StoneCountPanel/StoneHint.hide()
	$Control/StoneCountPanel/StoneTitle.add_theme_font_size_override("font_size", 22)
	$Control/StoneCountPanel/StoneCountLabel.add_theme_font_size_override("font_size", 34)
	for meter in [rowing_container, alert_container]:
		meter.get_node("Title").add_theme_font_size_override("font_size", 22)
		meter.get_node("Value").add_theme_font_size_override("font_size", 22)
		meter.get_node("Status").add_theme_font_size_override("font_size", 18)
	minimap_panel.get_node("Title").add_theme_font_size_override("font_size", 22)
	for label in ["LevelTag", "PlayerLegend", "EnemyLegend", "RockLegend", "GoalLegend"]:
		minimap_panel.get_node(label).hide()
	rowing_container.position = Vector2(24, 146)
	alert_container.position = Vector2(380, 146)
	$Control/DetectionContainer.position = Vector2(24, 144)
	minimap_panel.offset_left = -306
	minimap_panel.offset_right = -26
	minimap_panel.offset_top = 142
	minimap_panel.offset_bottom = 362
	# Sits just above the notice panel, inside the strip free of touch controls.
	var strip: Vector2 = mobile_controls.message_strip()
	var half_width: float = get_viewport().get_visible_rect().size.x * 0.5
	interaction_prompt.offset_top = -214
	interaction_prompt.offset_bottom = -164
	interaction_prompt.offset_left = strip.x - half_width
	interaction_prompt.offset_right = strip.y - half_width
	interaction_prompt.add_theme_font_size_override("font_size", 28)
	alpha_complete_panel.offset_left = -530
	alpha_complete_panel.offset_right = 530
	alpha_complete_panel.offset_top = -270
	alpha_complete_panel.offset_bottom = 270
	$Control/AlphaCompletePanel/TopAccent.offset_right = 1024
	$Control/AlphaCompletePanel/ChapterLabel.offset_right = 1026
	$Control/AlphaCompletePanel/ChapterLabel.add_theme_font_size_override("font_size", 24)
	$Control/AlphaCompletePanel/TitleLabel.add_theme_font_size_override("font_size", 39)
	$Control/AlphaCompletePanel/TitleRule.offset_left = 180
	$Control/AlphaCompletePanel/TitleRule.offset_right = 880
	var buttons: VBoxContainer = alpha_complete_panel.get_node("VBoxContainer")
	buttons.offset_left = -430
	buttons.offset_right = 430
	buttons.offset_top = -296
	for button in [next_level_button, restart_button, menu_button]:
		button.custom_minimum_size.y = 82
		button.add_theme_font_size_override("font_size", 30)
	var message: Label = alpha_complete_panel.get_node("MessageLabel")
	message.anchor_top = 0
	message.anchor_bottom = 0
	message.offset_top = 160
	message.offset_bottom = 234
	message.offset_left = -460
	message.offset_right = 460
	message.add_theme_font_size_override("font_size", 27)

func update_objective(text: String) -> void:
	if objective_label:
		objective_label.text = text

func update_stone_count(count: int) -> void:
	if stone_count_label:
		stone_count_label.text = "%02d" % count

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

func show_lake_hud(show: bool = true) -> void:
	if rowing_container:
		rowing_container.visible = show
	if alert_container:
		alert_container.visible = show
	if speed_label:
		speed_label.visible = show
	if minimap_panel:
		minimap_panel.visible = show
	if stone_count_label:
		stone_count_label.get_parent().visible = not show

func update_stamina(current: float, maximum: float) -> void:
	if rowing_container:
		rowing_container.set_ratio(current / maximum if maximum > 0.0 else 0.0)

func update_alert(ratio: float) -> void:
	if alert_container:
		alert_container.set_ratio(ratio)

func update_speed(current_speed: float) -> void:
	if speed_label:
		speed_label.text = "VELOCIDAD: " + str(int(round(current_speed)))

func show_interaction_prompt(prompt_text: String = "[E] HABLAR") -> void:
	if interaction_prompt:
		interaction_prompt.text = prompt_text.replace("[E]", "[ACCIÓN]") if mobile_controls.enabled else prompt_text
		interaction_prompt.visible = true

func hide_interaction_prompt() -> void:
	if interaction_prompt:
		interaction_prompt.visible = false

func show_temporary_notification(message: String, duration: float = 2.0) -> void:
	if notification_panel:
		notification_panel.show_message(message, duration)

func show_alpha_complete() -> void:
	if alpha_complete_panel:
		complete_backdrop.visible = true
		alpha_complete_panel.visible = true
	var pasco = get_tree().get_first_node_in_group("player")
	if pasco and pasco.has_method("set_movement_enabled"):
		pasco.set_movement_enabled(false)

func show_level_complete(title: String, message: String) -> void:
	if alpha_complete_panel:
		complete_backdrop.visible = true
		alpha_complete_panel.visible = true
		var title_label = alpha_complete_panel.get_node_or_null("TitleLabel") as Label
		var message_label = alpha_complete_panel.get_node_or_null("MessageLabel") as Label
		var next_button = alpha_complete_panel.get_node_or_null("VBoxContainer/NextLevelButton") as Button
		var restart = alpha_complete_panel.get_node_or_null("VBoxContainer/RestartButton") as Button
		if title_label: title_label.text = title
		if message_label: message_label.text = message
		if next_button: next_button.text = "VER LO QUE SIGUE"
		if restart: restart.text = "REPETIR LA TRAVESÍA"
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)

func hide_alpha_complete() -> void:
	if alpha_complete_panel:
		alpha_complete_panel.visible = false
	complete_backdrop.visible = false

func _on_restart_pressed() -> void:
	restart_requested.emit()

func _on_next_level_pressed() -> void:
	next_level_requested.emit()

func _on_menu_pressed() -> void:
	menu_requested.emit()
