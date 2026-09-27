extends Control
## Cinemática inicial del nivel 1. La lanza el botón JUGAR del menú: reproduce el vídeo con la música del
## nivel de fondo y pasa al nivel al terminar o al pulsar SALTAR CINEMÁTICA (también con Esc).

const MenuSkin = preload("res://scripts/menu_skin.gd")

const LEVEL_PATH := "res://scenes/levels/Level01_Convoy.tscn"
const VIDEO_SIZE := Vector2(1280.0, 720.0)
const MUSIC_VOLUME := 0.35
const FADE_TIME := 0.8

@onready var mobile_controls: Node = get_node("/root/MobileControls")
@onready var video: VideoStreamPlayer = $Video
@onready var music: AudioStreamPlayer = $Music
@onready var fade: ColorRect = $Fade
@onready var skip_button: Button = $SkipButton

var leaving := false
var level_requested := false

func _ready() -> void:
	MenuSkin.style_button(skip_button)
	if mobile_controls.enabled:
		skip_button.offset_left = -340.0
		skip_button.offset_top = -112.0
		skip_button.offset_bottom = -32.0
		skip_button.add_theme_font_size_override("font_size", 28)
	skip_button.pressed.connect(_leave)
	video.finished.connect(_leave)
	get_viewport().size_changed.connect(_fit_video)
	_fit_video()
	music.volume_db = linear_to_db(MUSIC_VOLUME)
	music.play()
	video.play()
	_after_start()

func _fit_video() -> void:
	var area := get_viewport().get_visible_rect().size
	video.size = VIDEO_SIZE * minf(area.x / VIDEO_SIZE.x, area.y / VIDEO_SIZE.y)
	video.position = (area - video.size) * 0.5

func _after_start() -> void:
	await get_tree().create_timer(0.6).timeout
	if leaving:
		return
	if not video.is_playing():
		_leave()
		return
	# Con el vídeo ya en marcha se va cargando el nivel para que no haya espera al terminar.
	level_requested = ResourceLoader.load_threaded_request(LEVEL_PATH) == OK
	skip_button.grab_focus()

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
	fade_out.tween_property(music, "volume_db", -60.0, FADE_TIME)
	fade_out.tween_property(video, "volume_db", -60.0, FADE_TIME)
	await fade_out.finished
	video.stop()
	music.stop()
	var level: PackedScene = null
	if level_requested:
		level = ResourceLoader.load_threaded_get(LEVEL_PATH) as PackedScene
	if level == null:
		level = load(LEVEL_PATH) as PackedScene
	get_tree().change_scene_to_packed(level)
