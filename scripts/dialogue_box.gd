extends CanvasLayer
class_name DialogueBox

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
		speaker_label.text = line_data.get("speaker", "")
		text_label.text = line_data.get("text", "")
		if next_prompt:
			next_prompt.text = "[Presiona E o Enter para continuar]"
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

	var pasco = get_tree().get_first_node_in_group("player")
	if pasco and pasco.has_method("set_movement_enabled"):
		pasco.set_movement_enabled(true)

	dialogue_finished.emit()
