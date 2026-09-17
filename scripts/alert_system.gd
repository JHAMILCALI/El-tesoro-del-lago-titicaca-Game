extends Node
class_name AlertSystem

signal alert_changed(value: float)

@export_range(0.0, 1.0) var value: float = 0.0
@export var calm_decay_per_second: float = 0.025
var danger_sources: int = 0
var hidden_sources: int = 0

func _process(delta: float) -> void:
	var decay := calm_decay_per_second
	if hidden_sources > 0:
		decay *= 2.5
	if danger_sources == 0:
		set_value(value - decay * delta)

func add(amount: float) -> void:
	set_value(value + amount)

func set_danger(active: bool) -> void:
	danger_sources += 1 if active else -1
	danger_sources = maxi(0, danger_sources)

func set_hidden(active: bool) -> void:
	hidden_sources += 1 if active else -1
	hidden_sources = maxi(0, hidden_sources)

func set_value(new_value: float) -> void:
	var clamped := clampf(new_value, 0.0, 1.0)
	if not is_equal_approx(value, clamped):
		value = clamped
		alert_changed.emit(value)
