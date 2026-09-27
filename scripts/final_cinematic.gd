extends Control

const MenuSkin = preload("res://scripts/menu_skin.gd")

const ENDING_PATH := "res://scenes/levels/Level03_Transition.tscn"
const VIDEO_SIZE := Vector2(1280.0, 720.0)
const FADE_TIME := 0.25

@onready var video: VideoStreamPlayer = $Video
@onready var fade: ColorRect = $Fade
@onready var skip_button: Button = $SkipButton

var leaving := false

func _ready() -> void:
	MenuSkin.style_button(skip_button)
	var mobile_controls: Node = get_node_or_null("/root/MobileControls")
	if mobile_controls != null and mobile_controls.enabled:
		skip_button.offset_left = -340.0
		skip_button.offset_top = -112.0
		skip_button.offset_bottom = -32.0
		skip_button.add_theme_font_size_override("font_size", 28)
	skip_button.pressed.connect(_leave)
	video.finished.connect(_leave)
	get_viewport().size_changed.connect(_fit_video)
	_fit_video()
	video.play()
	_check_playback()

func _fit_video() -> void:
	var area := get_viewport().get_visible_rect().size
	video.size = VIDEO_SIZE * minf(area.x / VIDEO_SIZE.x, area.y / VIDEO_SIZE.y)
	video.position = (area - video.size) * 0.5

func _check_playback() -> void:
	await get_tree().create_timer(0.6).timeout
	if not leaving and not video.is_playing():
		_leave()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_leave()

func _leave() -> void:
	if leaving:
		return
	leaving = true
	skip_button.hide()
	var fade_out := create_tween().set_parallel(true)
	fade_out.tween_property(fade, "color:a", 1.0, FADE_TIME)
	fade_out.tween_property(video, "volume_db", -60.0, FADE_TIME)
	await fade_out.finished
	video.stop()
	get_tree().change_scene_to_file(ENDING_PATH)
