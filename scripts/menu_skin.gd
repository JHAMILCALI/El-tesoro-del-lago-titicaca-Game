extends RefCounted

const GOLD := Color("d9ac62")
const CREAM := Color("fff0d3")
const DEEP_BLUE := Color("102b35")

static func style_button(button: Button, primary: bool = false) -> void:
	button.add_theme_stylebox_override("normal", _button_box(primary, false, false))
	button.add_theme_stylebox_override("hover", _button_box(primary, true, false))
	button.add_theme_stylebox_override("pressed", _button_box(primary, false, true))
	button.add_theme_stylebox_override("focus", _focus_box())
	button.add_theme_color_override("font_color", DEEP_BLUE if primary else CREAM)
	button.add_theme_color_override("font_hover_color", DEEP_BLUE if primary else Color.WHITE)
	button.add_theme_color_override("font_pressed_color", DEEP_BLUE if primary else Color.WHITE)
	button.add_theme_color_override("font_focus_color", DEEP_BLUE if primary else CREAM)
	button.add_theme_color_override("font_disabled_color", Color("958a72"))
	button.add_theme_constant_override("h_separation", 12)
	button.focus_mode = Control.FOCUS_ALL

static func _button_box(primary: bool, hovered: bool, pressed: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = (Color("f4d08b") if hovered else Color("d9ac62")) if primary else (Color("315261") if hovered else Color("193945"))
	if pressed:
		box.bg_color = Color("bf8d4a") if primary else Color("456070")
	box.border_color = Color("ffe5ad") if hovered else GOLD
	box.set_border_width_all(2)
	box.set_corner_radius_all(7)
	box.set_content_margin_all(10)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 3
	return box

static func _focus_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color.TRANSPARENT
	box.border_color = Color("fff0c2")
	box.set_border_width_all(3)
	box.set_corner_radius_all(8)
	box.expand_margin_left = 2
	box.expand_margin_top = 2
	box.expand_margin_right = 2
	box.expand_margin_bottom = 2
	return box
