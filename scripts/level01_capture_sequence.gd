extends CanvasLayer

signal finished

const DURATION := 4.0

@onready var stage: Node2D = $Screen/Stage

var playing := false

func _ready() -> void:
	_fit_viewport()
	get_viewport().size_changed.connect(_fit_viewport)

func _fit_viewport() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	stage.position = viewport_size * 0.5
	stage.scale = Vector2.ONE * minf(viewport_size.x / 800.0, viewport_size.y / 560.0)

func play() -> void:
	if playing:
		return
	playing = true
	var sequence := create_tween().set_parallel(true)
	sequence.tween_property($Screen/Veil, "color:a", 0.94, 0.25)
	sequence.tween_property(stage, "modulate:a", 1.0, 0.25)
	sequence.tween_property($Screen/Stage/GuardLeft, "position:x", -106.0, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sequence.tween_property($Screen/Stage/GuardRight, "position:x", 106.0, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sequence.tween_callback(_show_capture).set_delay(1.15)
	sequence.tween_callback(_show_return_message).set_delay(2.8)
	sequence.tween_property($Screen/Fade, "color:a", 1.0, 0.55).set_delay(DURATION - 0.55)
	await sequence.finished
	finished.emit()

func _show_capture() -> void:
	$Screen/Stage/Pasco.hide()
	$Screen/Stage/GuardLeft.hide()
	$Screen/Stage/GuardRight.hide()
	$Screen/Stage/Title.text = "¡CAPTURADO!"
	$Screen/Stage/Caption.text = "Los españoles han detenido a Pasco."
	var captured: Sprite2D = $Screen/Stage/Captured
	var impact: Line2D = $Screen/Stage/Impact
	impact.modulate.a = 1.0
	impact.scale = Vector2.ONE * 0.55
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(captured, "modulate:a", 1.0, 0.18)
	reveal.tween_property(captured, "scale", Vector2.ONE * 0.36, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.tween_property(impact, "scale", Vector2.ONE * 2.4, 0.48)
	reveal.tween_property(impact, "modulate:a", 0.0, 0.48)

func _show_return_message() -> void:
	$Screen/Stage/Caption.text = "Regresando al último punto seguro…"
