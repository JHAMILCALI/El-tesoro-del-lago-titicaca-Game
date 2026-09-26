extends CanvasLayer
class_name DialogueBox

@onready var mobile_controls: Node = get_node("/root/MobileControls")

signal dialogue_started
signal dialogue_finished

@onready var panel: Panel = $Panel
@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var text_label: Label = $Panel/TextLabel
@onready var next_prompt: Label = $Panel/NextPrompt

var current_lines: Array = []
var line_index: int = 0
var is_active: bool = false

func _ready() -> void:
	visible = false
	if panel:
		panel.visible = false
	mobile_controls.touch_mode_changed.connect(_apply_touch_layout)
	_apply_touch_layout()

func _apply_touch_layout() -> void:
	if not mobile_controls.enabled:
		return
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = -390
	panel.offset_bottom = -135
	speaker_label.add_theme_font_size_override("font_size", 28)
	text_label.add_theme_font_size_override("font_size", 28)
	text_label.anchor_right = 1.0
	text_label.offset_right = -24
	text_label.offset_top = 65
	text_label.offset_bottom = 240
	next_prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		advance_dialogue()

func start_dialogue(lines: Array) -> void:
	current_lines = lines
	line_index = 0
	is_active = true
	visible = true
	if panel:
		panel.visible = true

	var pasco = get_tree().get_first_node_in_group("player")
	if pasco and pasco.has_method("set_movement_enabled"):
		pasco.set_movement_enabled(false)

	dialogue_started.emit()
	_show_current_line()

func _show_current_line() -> void:
	if line_index < current_lines.size():
		var line_data: Dictionary = current_lines[line_index]
		var speaker: String = line_data.get("speaker", "")
		speaker_label.text = speaker
		text_label.text = line_data.get("text", "")
		if next_prompt:
			next_prompt.text = "Toca CONTINUAR" if mobile_controls.enabled else "[Presiona E o Enter para continuar]"

		for node in get_tree().get_nodes_in_group("npc"):
			if node is Huita:
				if speaker == "Huita":
					var pasco = get_tree().get_first_node_in_group("player")
					var look_pos = pasco.global_position if pasco else Vector2.ZERO
					node.start_talking(look_pos)
				else:
					node.stop_talking()
	else:
		_end_dialogue()

func advance_dialogue() -> void:
	line_index += 1
	if line_index < current_lines.size():
		_show_current_line()
	else:
		_end_dialogue()

func _end_dialogue() -> void:
	is_active = false
	visible = false
	if panel:
		panel.visible = false

	for node in get_tree().get_nodes_in_group("npc"):
		if node is Huita:
			node.stop_talking()

	var pasco = get_tree().get_first_node_in_group("player")
	if pasco and pasco.has_method("set_movement_enabled"):
		pasco.set_movement_enabled(true)

	dialogue_finished.emit()
