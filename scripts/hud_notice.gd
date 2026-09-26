extends Panel
class_name HudNotice

@onready var mobile_controls: Node = get_node("/root/MobileControls")

const PALE_TEXT := Color("fff2dc")
const GOLD := Color("e4b65f")
const AMBER := Color("edaa53")
const RED := Color("f17a66")
const TEAL := Color("67d4bd")

@onready var heading: Label = $Heading
@onready var message_label: Label = $NotificationLabel
@onready var accent: ColorRect = $Accent
@onready var symbol: Label = $Symbol
@onready var hide_timer: Timer = $HideTimer

var panel_style: StyleBoxFlat
var long_message := false

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_style = (get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	add_theme_stylebox_override("panel", panel_style)
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	get_viewport().size_changed.connect(_layout_panel)
	mobile_controls.touch_mode_changed.connect(_layout_panel)
	_layout_panel()
	var strong_font := FontVariation.new()
	strong_font.base_font = ThemeDB.fallback_font
	strong_font.variation_embolden = 0.45
	message_label.add_theme_font_override("font", strong_font)
	heading.add_theme_font_override("font", strong_font)

func show_message(message: String, duration: float) -> void:
	var shown_text := message.strip_edges()
	var lowered := shown_text.to_lower()
	var tone := GOLD
	var category := "AVISO"
	var icon := "◆"
	if lowered.begins_with("objetivo:"):
		category = "NUEVO OBJETIVO"
		tone = TEAL
		icon = "➜"
		shown_text = shown_text.substr(shown_text.find(":") + 1).strip_edges()
	elif lowered == "oculto":
		category = "SIGILO"
		tone = TEAL
	elif lowered.contains("ruido") or lowered.contains("alerta") or lowered.contains("descubierto"):
		category = "PELIGRO"
		tone = RED
		icon = "!"
	elif lowered.contains("sin piedras") or lowered.contains("debes hablar"):
		category = "ATENCIÓN"
		tone = AMBER
		icon = "!"
	elif lowered.contains("checkpoint") or lowered.contains("recuperad") or lowered.contains("recolectad") or lowered.contains("completado") or lowered.contains("abierto") or lowered.contains("desmayada"):
		category = "PROGRESO"
		tone = TEAL
		icon = "✓"

	heading.text = category
	heading.add_theme_color_override("font_color", tone)
	message_label.text = shown_text
	message_label.add_theme_color_override("font_color", PALE_TEXT)
	symbol.text = icon
	symbol.add_theme_color_override("font_color", tone)
	accent.color = tone
	panel_style.border_color = tone.darkened(0.3)
	panel_style.bg_color = Color("211b18").lerp(tone, 0.08)
	panel_style.bg_color.a = 0.97
	message_label.add_theme_font_size_override("font_size", 22 if shown_text.length() <= 25 else 17)
	if mobile_controls.enabled:
		message_label.add_theme_font_size_override("font_size", 24)
	long_message = shown_text.length() > 45
	_layout_panel()
	visible = true
	hide_timer.start(maxf(duration, 0.25))

func _layout_panel() -> void:
	var viewport_width := get_viewport_rect().size.x
	var panel_width := minf(520.0, viewport_width - 32.0)
	var panel_height := 90.0 if long_message else 70.0
	var center_x := 0.0
	if mobile_controls.enabled:
		# Bottom strip between the joystick and the action buttons keeps Pasco visible.
		var strip: Vector2 = mobile_controls.message_strip()
		panel_width = maxf(240.0, minf(640.0, strip.y - strip.x))
		panel_height = 120.0 if long_message else 90.0
		center_x = (strip.x + strip.y) * 0.5 - viewport_width * 0.5
		anchor_top = 1.0
		anchor_bottom = 1.0
		offset_bottom = -24.0
		offset_top = offset_bottom - panel_height
	else:
		offset_top = 114.0 if viewport_width >= 1040.0 else 310.0
		offset_bottom = offset_top + panel_height
	offset_left = center_x - panel_width * 0.5
	offset_right = center_x + panel_width * 0.5
	accent.position = Vector2(13, 12)
	accent.size = Vector2(4, panel_height - 24.0)
	symbol.position = Vector2(23, 27 if long_message else 21)
	symbol.size = Vector2(22, 32)
	heading.position = Vector2(52, 10)
	heading.size = Vector2(panel_width - 68.0, 17)
	message_label.position = Vector2(52, 28)
	message_label.size = Vector2(panel_width - 68.0, panel_height - 36.0)

func _on_hide_timer_timeout() -> void:
	visible = false
