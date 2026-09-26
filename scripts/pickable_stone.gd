extends Area2D
class_name PickableStone

const PICKUP_STREAM: AudioStream = preload("res://assets/audio/stone pickup.mp3")

@export var amount: int = 1

@onready var visual_rect: ColorRect = $VisualRect
@onready var label: Label = $Label

var is_collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return

	if body is Pasco or (body.has_method("add_stones")):
		is_collected = true
		body.add_stones(amount)

		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_temporary_notification"):
			hud.show_temporary_notification("+" + str(amount) + " Piedra recolectada", 1.8)

		_play_pickup_sound()
		queue_free()

func _play_pickup_sound() -> void:
	var sound_parent := get_parent()
	if not sound_parent:
		return
	var pickup_audio := AudioStreamPlayer2D.new()
	pickup_audio.name = "StonePickupAudio_%s" % get_instance_id()
	pickup_audio.stream = PICKUP_STREAM
	pickup_audio.volume_db = -5.0
	pickup_audio.max_distance = 650.0
	pickup_audio.attenuation = 1.2
	pickup_audio.add_to_group("one_shot_audio")
	pickup_audio.set_meta("sound_kind", &"stone_pickup")
	sound_parent.add_child(pickup_audio)
	pickup_audio.global_position = global_position
	pickup_audio.finished.connect(pickup_audio.queue_free)
	pickup_audio.play()
