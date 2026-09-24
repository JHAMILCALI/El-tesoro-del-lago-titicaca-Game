extends Sprite2D

@export_range(0.0, 1.0) var base_opacity := 0.44

var flow_axis := Vector2.RIGHT
var animation_time := 0.0

func configure(force: Vector2, area_size: Vector2) -> void:
	flow_axis = force.normalized() if force.length_squared() > 0.0 else Vector2.RIGHT
	rotation = flow_axis.angle()
	if texture:
		var texture_size := Vector2(texture.get_size())
		scale = Vector2(area_size.x / texture_size.x, area_size.y / texture_size.y) * Vector2(1.04, 0.92)

func _process(delta: float) -> void:
	animation_time += delta
	position = flow_axis * sin(animation_time * 1.8) * 6.0
	modulate.a = base_opacity * (0.9 + 0.1 * sin(animation_time * 2.7))
