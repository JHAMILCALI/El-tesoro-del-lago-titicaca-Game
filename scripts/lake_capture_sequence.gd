extends CanvasLayer

signal finished

const DURATION := 4.0

@onready var stage: Node2D = $Screen/Stage
@onready var player_sprite: PlayerBoatVisual = $Screen/Stage/Player
@onready var blocker: PlayerBoatVisual = $Screen/Stage/Blocker
@onready var left_escort: PlayerBoatVisual = $Screen/Stage/LeftEscort
@onready var right_escort: PlayerBoatVisual = $Screen/Stage/RightEscort

var playing := false

func _ready() -> void:
	_fit_viewport()
	get_viewport().size_changed.connect(_fit_viewport)
	var ring := PackedVector2Array()
	for index in 40:
		ring.append(Vector2.from_angle(TAU * float(index) / 40.0) * Vector2(48, 16))
	$Screen/Stage/Impact.points = ring

func _fit_viewport() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	stage.position = viewport_size * 0.5
	stage.scale = Vector2.ONE * minf(viewport_size.x / 800.0, viewport_size.y / 560.0)

func play() -> void:
	if playing:
		return
	playing = true
	for visual in [player_sprite, blocker, left_escort, right_escort]:
		visual.set_rowing(0.85)
	var sequence := create_tween().set_parallel(true)
	sequence.tween_property($Screen/Veil, "color:a", 0.94, 0.25)
	sequence.tween_property(stage, "modulate:a", 1.0, 0.25)
	sequence.tween_property(player_sprite, "position", Vector2(0, 30), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	sequence.tween_property(blocker, "position", Vector2(0, -94), 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sequence.tween_property(blocker, "rotation", PI * 0.5, 0.65).set_delay(0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sequence.tween_property(left_escort, "position", Vector2(-104, 36), 1.15).set_delay(0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sequence.tween_property(right_escort, "position", Vector2(104, 36), 1.15).set_delay(0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sequence.tween_callback(_restrain_boats).set_delay(1.3)
	sequence.tween_property($Screen/Stage/Ropes, "modulate:a", 1.0, 0.2).set_delay(1.3)
	sequence.tween_callback(_show_return_message).set_delay(2.8)
	sequence.tween_property($Screen/Fade, "color:a", 1.0, 0.55).set_delay(DURATION - 0.55)
	await sequence.finished
	finished.emit()

func _restrain_boats() -> void:
	for visual in [player_sprite, blocker, left_escort, right_escort]:
		visual.set_rowing(0.0)
	$Screen/Stage/Title.text = "¡CAPTURADOS!"
	$Screen/Stage/Caption.text = "Los españoles han detenido nuestra barca."
	var impact: Line2D = $Screen/Stage/Impact
	impact.modulate.a = 1.0
	impact.scale = Vector2.ONE * 0.5
	var splash := create_tween().set_parallel(true)
	splash.tween_property(impact, "scale", Vector2.ONE * 1.8, 0.5)
	splash.tween_property(impact, "modulate:a", 0.0, 0.5)
	var recoil := create_tween()
	recoil.tween_property(player_sprite, "position:y", 36.0, 0.08)
	recoil.tween_property(player_sprite, "position:y", 30.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _show_return_message() -> void:
	$Screen/Stage/Caption.text = "Regresando al muelle de partida…"
