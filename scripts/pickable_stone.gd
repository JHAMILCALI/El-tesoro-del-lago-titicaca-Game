extends Area2D
class_name PickableStone

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

		queue_free()
