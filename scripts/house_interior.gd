extends Node2D
class_name HouseInterior

signal enter_requested
signal exit_requested
signal treasure_requested
signal door_proximity_changed(is_near: bool)
signal exit_proximity_changed(is_near: bool)
signal treasure_proximity_changed(is_near: bool)

@onready var exterior_door_area: Area2D = $Exterior/DoorArea
@onready var interior_exit_area: Area2D = $Interior/ExitArea
@onready var treasure_area: Area2D = $Interior/TreasureArea
@onready var treasure_visual: ColorRect = $Interior/TreasureArea/TreasureVisual
@onready var treasure_label: Label = $Interior/TreasureArea/TreasureLabel
@onready var interior_spawn: Marker2D = $Interior/InteriorSpawn
@onready var exterior_spawn: Marker2D = $Exterior/ExteriorSpawn
@onready var treasure_checkpoint: Marker2D = $Interior/TreasureCheckpoint

var player_near_door: bool = false
var player_near_exit: bool = false
var player_near_treasure: bool = false
var treasure_available: bool = true

func _ready() -> void:
	exterior_door_area.body_entered.connect(_on_door_body_entered)
	exterior_door_area.body_exited.connect(_on_door_body_exited)
	interior_exit_area.body_entered.connect(_on_exit_body_entered)
	interior_exit_area.body_exited.connect(_on_exit_body_exited)
	treasure_area.body_entered.connect(_on_treasure_body_entered)
	treasure_area.body_exited.connect(_on_treasure_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or event.is_echo():
		return

	if player_near_treasure and treasure_available:
		get_viewport().set_input_as_handled()
		treasure_requested.emit()
	elif player_near_exit:
		get_viewport().set_input_as_handled()
		exit_requested.emit()
	elif player_near_door:
		get_viewport().set_input_as_handled()
		enter_requested.emit()

func collect_treasure() -> void:
	treasure_available = false
	player_near_treasure = false
	treasure_visual.visible = false
	treasure_label.visible = false
	treasure_area.monitoring = false
	treasure_area.monitorable = false

func get_interior_spawn_position() -> Vector2:
	return interior_spawn.global_position

func get_exterior_spawn_position() -> Vector2:
	return exterior_spawn.global_position

func get_treasure_checkpoint_position() -> Vector2:
	return treasure_checkpoint.global_position

func _on_door_body_entered(body: Node2D) -> void:
	if body is Pasco:
		player_near_door = true
		door_proximity_changed.emit(true)

func _on_door_body_exited(body: Node2D) -> void:
	if body is Pasco:
		player_near_door = false
		door_proximity_changed.emit(false)

func _on_exit_body_entered(body: Node2D) -> void:
	if body is Pasco:
		player_near_exit = true
		exit_proximity_changed.emit(true)

func _on_exit_body_exited(body: Node2D) -> void:
	if body is Pasco:
		player_near_exit = false
		exit_proximity_changed.emit(false)

func _on_treasure_body_entered(body: Node2D) -> void:
	if body is Pasco and treasure_available:
		player_near_treasure = true
		treasure_proximity_changed.emit(true)

func _on_treasure_body_exited(body: Node2D) -> void:
	if body is Pasco:
		player_near_treasure = false
		treasure_proximity_changed.emit(false)
