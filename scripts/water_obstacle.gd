extends StaticBody2D
class_name WaterObstacle

@export var impact_message: String = "¡Impacto contra una roca! La barca pierde velocidad."

func handle_boat_collision(body: BoatPrototype, collision_normal: Vector2) -> void:
	# The solid body blocks passage; the boat's cooldown also gates alerts and messages.
	if not body.apply_impact(global_position, collision_normal):
		return
	var level = get_tree().get_first_node_in_group("lake_level")
	if level and level.has_method("show_notification"):
		level.show_notification(impact_message, 1.2)
	if level and level.has_method("add_alert"):
		level.add_alert(0.08)
