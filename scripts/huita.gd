extends CharacterBody2D
class_name Huita

signal interaction_requested
signal player_proximity_changed(is_near: bool)

@export var follow_speed: float = 165.0
@export var stop_distance: float = 55.0

var is_player_near: bool = false
var is_following: bool = false
var is_hidden: bool = false
var target_player: CharacterBody2D = null

@onready var interaction_area: Area2D = $InteractionArea
@onready var label: Label = $Label

func _ready() -> void:
	add_to_group("allies")
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	if not is_following or not target_player:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	is_hidden = target_player.get("is_hidden") == true
	var dist = global_position.distance_to(target_player.global_position)
	if dist > stop_distance:
		var dir = (target_player.global_position - global_position).normalized()
		velocity = dir * follow_speed
		rotation = lerp_angle(rotation, dir.angle(), _delta * 6.0)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func start_following(player: CharacterBody2D) -> void:
	target_player = player
	is_following = true
	is_player_near = false
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("hide_interaction_prompt"):
		hud.hide_interaction_prompt()

func stop_following() -> void:
	is_following = false
	velocity = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if is_following:
		return
	if is_player_near and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interaction_requested.emit()

func _on_body_entered(body: Node2D) -> void:
	if is_following:
		return
	if body is Pasco:
		is_player_near = true
		player_proximity_changed.emit(true)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_interaction_prompt"):
			hud.show_interaction_prompt("[E] HABLAR")

func _on_body_exited(body: Node2D) -> void:
	if is_following:
		return
	if body is Pasco:
		is_player_near = false
		player_proximity_changed.emit(false)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("hide_interaction_prompt"):
			hud.hide_interaction_prompt()
