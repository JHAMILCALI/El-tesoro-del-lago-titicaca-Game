extends Area2D
class_name WaterObstacle

@export var impact_message: String = "¡Impacto!"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is BoatPrototype:
		body.apply_impact(global_position)
		var level = get_tree().get_first_node_in_group("lake_level")
		if level and level.has_method("show_notification"):
			level.show_notification(impact_message, 1.2)
		if level and level.has_method("add_alert"):
			level.add_alert(0.08)
