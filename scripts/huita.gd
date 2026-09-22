extends CharacterBody2D
class_name Huita

signal interaction_requested
signal player_proximity_changed(is_near: bool)

@export var follow_speed: float = 165.0
@export var follow_distance: float = 70.0
@export var stop_distance: float = 45.0
@export var formation_offset: float = 55.0
@export var overlap_distance: float = 25.0
@export var recovery_distance: float = 300.0
@export var recovery_delay: float = 2.0

var is_player_near: bool = false
var is_following: bool = false
var is_hidden: bool = false
var is_talking: bool = false
var target_player: CharacterBody2D = null
var stuck_time: float = 0.0
var previous_position: Vector2
var facing_direction: Vector2 = Vector2.DOWN

@onready var interaction_area: Area2D = $InteractionArea
@onready var label: Label = $Label
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("allies")
	add_to_group("npc")
	previous_position = global_position
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	_update_animation(Vector2.ZERO)

func _physics_process(delta: float) -> void:
	if not is_following or not target_player:
		velocity = Vector2.ZERO
		move_and_slide()
		stuck_time = 0.0
		previous_position = global_position
		_update_animation(Vector2.ZERO)
		return

	is_hidden = target_player.get("is_hidden") == true
	var player_direction := _get_player_direction()
	var player_distance := global_position.distance_to(target_player.global_position)
	var follow_target := target_player.global_position - player_direction * formation_offset

	if player_distance < overlap_distance:
		follow_target = target_player.global_position - player_direction * follow_distance

	var distance_to_target := global_position.distance_to(follow_target)
	if distance_to_target > stop_distance:
		var direction := (follow_target - global_position).normalized()
		velocity = direction * follow_speed
		facing_direction = direction
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_update_animation(velocity)
	_update_stuck_recovery(delta, player_distance, player_direction)
	previous_position = global_position

func start_talking(look_at_pos: Vector2 = Vector2.ZERO) -> void:
	is_talking = true
	if look_at_pos != Vector2.ZERO:
		facing_direction = (look_at_pos - global_position).normalized()
	_update_animation(Vector2.ZERO)

func stop_talking() -> void:
	is_talking = false
	_update_animation(velocity)

func _update_animation(movement: Vector2) -> void:
	if not animated_sprite:
		return

	if is_talking:
		var talk_anim := _directional_animation(&"talk", facing_direction)
		if animated_sprite.animation != talk_anim or not animated_sprite.is_playing():
			animated_sprite.play(talk_anim)
		return

	var is_moving := movement.length_squared() > 1.0
	if is_moving:
		facing_direction = movement.normalized()
		var walk_anim := _directional_animation(&"walk", facing_direction)
		if animated_sprite.animation != walk_anim or not animated_sprite.is_playing():
			animated_sprite.play(walk_anim)
	else:
		var idle_anim := _directional_animation(&"idle", facing_direction)
		if animated_sprite.animation != idle_anim:
			animated_sprite.play(idle_anim)

func _directional_animation(prefix: StringName, direction: Vector2) -> StringName:
	var suffix := "down"
	if absf(direction.x) > absf(direction.y):
		suffix = "right" if direction.x > 0.0 else "left"
	elif direction.y < 0.0:
		suffix = "up"
	return StringName(String(prefix) + "_" + suffix)

func _get_player_direction() -> Vector2:
	var player_direction: Vector2 = target_player.get("last_direction")
	return player_direction.normalized() if player_direction.length_squared() > 0.001 else Vector2.DOWN

func _update_stuck_recovery(delta: float, player_distance: float, player_direction: Vector2) -> void:
	var is_trying_to_move := velocity.length_squared() > 1.0
	var barely_moved := global_position.distance_to(previous_position) < 2.0 * delta
	if player_distance > recovery_distance and is_trying_to_move and barely_moved:
		stuck_time += delta
	else:
		stuck_time = 0.0

	if stuck_time >= recovery_delay:
		global_position = target_player.global_position - player_direction * follow_distance
		velocity = Vector2.ZERO
		stuck_time = 0.0

func start_following(player: CharacterBody2D) -> void:
	target_player = player
	is_following = true
	is_player_near = false
	stuck_time = 0.0
	previous_position = global_position
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("hide_interaction_prompt"):
		hud.hide_interaction_prompt()

func stop_following() -> void:
	is_following = false
	velocity = Vector2.ZERO
	stuck_time = 0.0
	_update_animation(Vector2.ZERO)

func _unhandled_input(event: InputEvent) -> void:
	if is_following:
		return
	if is_player_near and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interaction_requested.emit()

func _on_body_entered(body: Node2D) -> void:
	if is_following:
		return
	if body.is_in_group("player"):
		is_player_near = true
		player_proximity_changed.emit(true)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_interaction_prompt"):
			hud.show_interaction_prompt("[E] HABLAR")

func _on_body_exited(body: Node2D) -> void:
	if is_following:
		return
	if body.is_in_group("player"):
		is_player_near = false
		player_proximity_changed.emit(false)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("hide_interaction_prompt"):
			hud.hide_interaction_prompt()
