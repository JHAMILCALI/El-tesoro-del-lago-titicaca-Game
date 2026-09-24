@tool
extends Node2D
class_name PlayerBoatVisual

const EMPTY_TEXTURE = preload("res://assets/sprites/boat_empty_v2.png")
const CREWED_TEXTURE = preload("res://assets/sprites/boat_crewed_v2.png")

@export var crewed_texture: Texture2D = CREWED_TEXTURE:
	set(value):
		crewed_texture = value
		if is_node_ready():
			_update_hull()

@export var follow_parent_velocity: bool = false
@export_range(1.0, 500.0) var full_rowing_speed: float = 125.0

@export var crewed: bool = true:
	set(value):
		crewed = value
		if is_node_ready():
			_update_hull()

var rowing_strength := 0.0
var rowing_amount := 0.0
var stroke_phase := 0.0

func _ready() -> void:
	_update_hull()
	_update_oars()
	set_process(not Engine.is_editor_hint())

func set_crewed(value: bool) -> void:
	crewed = value

func set_rowing(strength: float) -> void:
	rowing_strength = clampf(strength, 0.0, 1.0)

func _process(delta: float) -> void:
	if follow_parent_velocity:
		var boat := get_parent() as CharacterBody2D
		var moving := boat != null and boat.is_physics_processing() and boat.is_visible_in_tree()
		set_rowing(boat.velocity.length() / full_rowing_speed if moving else 0.0)
	var target := rowing_strength if crewed else 0.0
	rowing_amount = move_toward(rowing_amount, target, delta * 3.0)
	stroke_phase = fmod(stroke_phase + delta * lerpf(1.5, 6.5, rowing_amount), TAU)
	_update_oars()

func _update_hull() -> void:
	$Hull.texture = (crewed_texture if crewed_texture else CREWED_TEXTURE) if crewed else EMPTY_TEXTURE

func _update_oars() -> void:
	# Rotate each paddle about its handle; both sides remain attached to the rower.
	var stroke := 0.1 + sin(stroke_phase) * 0.65
	var angle := lerpf(-1.12, stroke, rowing_amount)
	$LeftOar.rotation = angle
	$RightOar.rotation = -angle
