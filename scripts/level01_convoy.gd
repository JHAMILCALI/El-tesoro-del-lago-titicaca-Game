extends Node2D

enum StoryState {
	START,
	PATROL_ROUTE,
	HUITA_REACHED,
	HOUSE_OBJECTIVE,
	INSIDE_HOUSE,
	TREASURE_COLLECTED,
	COMPLETE
}

@onready var pasco: Pasco = $Pasco
@onready var huita: Huita = $Huita
@onready var spanish_patrol1: SpanishPatrol = $SpanishPatrol1
@onready var spanish_patrol2: SpanishPatrol = $SpanishPatrol2
@onready var hud: HUD = $HUD
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var house: HouseInterior = $HouseInterior

@onready var start_checkpoint: Node2D = $Checkpoints/StartCheckpoint
@onready var checkpoint_huita: Node2D = $Checkpoints/CheckpointHuita
@onready var checkpoint_house: Node2D = $Checkpoints/CheckpointHouse
@onready var tutorial_trigger_area: Area2D = $Areas/TutorialTriggerArea
@onready var hide_zones: Array[Area2D] = [
	$Areas/HideZone1,
	$Areas/HideZone2,
	$Areas/HideZone3,
	$Areas/HideZone4,
	$Areas/HideZone5,
	$Areas/HideZone6
]

var last_checkpoint_pos: Vector2
var story_state: StoryState = StoryState.START
var has_treasure: bool = false
var has_seen_tutorial: bool = false

func _ready() -> void:
	last_checkpoint_pos = start_checkpoint.global_position
	hud.update_objective("Avanza con cuidado por el camino.")
	hud.restart_requested.connect(_on_restart_requested)
	hud.menu_requested.connect(_on_menu_requested)

	huita.interaction_requested.connect(_on_huita_interaction)
	huita.player_proximity_changed.connect(_on_huita_proximity_changed)
	spanish_patrol1.player_captured.connect(_on_player_captured)
	spanish_patrol2.player_captured.connect(_on_player_captured)
	tutorial_trigger_area.body_entered.connect(_on_tutorial_trigger_entered)

	for hide_zone in hide_zones:
		hide_zone.body_entered.connect(_on_hide_zone_entered)
		hide_zone.body_exited.connect(_on_hide_zone_exited)

	house.enter_requested.connect(_on_house_enter_requested)
	house.exit_requested.connect(_on_house_exit_requested)
	house.treasure_requested.connect(_on_treasure_requested)
	house.door_proximity_changed.connect(_on_house_door_proximity_changed)
	house.exit_proximity_changed.connect(_on_house_exit_proximity_changed)
	house.treasure_proximity_changed.connect(_on_treasure_proximity_changed)

func _on_tutorial_trigger_entered(body: Node2D) -> void:
	if body is not Pasco or has_seen_tutorial:
		return

	has_seen_tutorial = true
	if story_state == StoryState.START:
		story_state = StoryState.PATROL_ROUTE
	hud.update_objective("Evita a la patrulla y llega hasta Huita.")
	hud.show_temporary_notification("Usa los arbustos para ocultarte.", 2.5)

func _on_huita_proximity_changed(is_near: bool) -> void:
	if is_near and story_state <= StoryState.HUITA_REACHED:
		story_state = StoryState.HUITA_REACHED
		hud.update_objective("Habla con Huita.")

func _on_huita_interaction() -> void:
	if story_state > StoryState.HUITA_REACHED:
		return

	story_state = StoryState.HOUSE_OBJECTIVE
	last_checkpoint_pos = checkpoint_huita.global_position

	var lines: Array = [
		{"speaker": "Huita", "text": "Pasco, debemos actuar con cuidado."},
		{"speaker": "Pasco", "text": "Los españoles están cerca."},
		{"speaker": "Huita", "text": "Tengo noticias. El tesoro está escondido en una casa más adelante."},
		{"speaker": "Pasco", "text": "Entonces tengo que recuperar el tesoro."},
		{"speaker": "Huita", "text": "Ve con cuidado. No dejes que te descubran."}
	]

	dialogue_box.start_dialogue(lines)
	dialogue_box.dialogue_finished.connect(func() -> void:
		hud.update_objective("Entra en la casa y recupera el tesoro.")
		hud.show_temporary_notification("Checkpoint alcanzado", 2.0)
	, CONNECT_ONE_SHOT)

func _on_house_door_proximity_changed(is_near: bool) -> void:
	if not is_near:
		hud.hide_interaction_prompt()
		return

	if story_state < StoryState.HOUSE_OBJECTIVE:
		hud.show_interaction_prompt("Habla primero con Huita")
	else:
		hud.show_interaction_prompt("[E] Entrar")

func _on_house_enter_requested() -> void:
	if story_state < StoryState.HOUSE_OBJECTIVE:
		hud.show_temporary_notification("Debes hablar con Huita primero.", 2.0)
		return
	if story_state == StoryState.COMPLETE:
		return

	story_state = StoryState.INSIDE_HOUSE if not has_treasure else StoryState.TREASURE_COLLECTED
	last_checkpoint_pos = checkpoint_house.global_position
	_teleport_player(house.get_interior_spawn_position())
	hud.hide_interaction_prompt()
	if has_treasure:
		hud.update_objective("Sal de la casa.")
	else:
		hud.update_objective("Recoge el tesoro.")
		hud.show_temporary_notification("Checkpoint alcanzado", 1.5)

func _on_house_exit_proximity_changed(is_near: bool) -> void:
	if is_near:
		hud.show_interaction_prompt("[E] Salir")
	else:
		hud.hide_interaction_prompt()

func _on_house_exit_requested() -> void:
	if story_state < StoryState.INSIDE_HOUSE:
		return

	_teleport_player(house.get_exterior_spawn_position())
	hud.hide_interaction_prompt()

	if has_treasure:
		story_state = StoryState.COMPLETE
		hud.update_objective("Objetivo completado: tesoro recuperado.")
		hud.show_temporary_notification("Objetivo completado", 2.5)
		hud.show_alpha_complete()
	else:
		story_state = StoryState.HOUSE_OBJECTIVE
		hud.update_objective("Entra en la casa y recupera el tesoro.")

func _on_treasure_proximity_changed(is_near: bool) -> void:
	if is_near and not has_treasure:
		hud.show_interaction_prompt("[E] Recoger tesoro")
	else:
		hud.hide_interaction_prompt()

func _on_treasure_requested() -> void:
	if story_state != StoryState.INSIDE_HOUSE or has_treasure:
		return

	has_treasure = true
	story_state = StoryState.TREASURE_COLLECTED
	house.collect_treasure()
	last_checkpoint_pos = house.get_treasure_checkpoint_position()
	hud.hide_interaction_prompt()
	hud.update_objective("Sal de la casa.")
	hud.show_temporary_notification("Tesoro recuperado", 2.5)

func _on_hide_zone_entered(body: Node2D) -> void:
	if body is Pasco:
		body.enter_hide_area()
		hud.show_temporary_notification("OCULTO", 1.5)

func _on_hide_zone_exited(body: Node2D) -> void:
	if body is Pasco:
		body.exit_hide_area()

func _on_player_captured() -> void:
	hud.update_detection_progress(0.0)
	hud.show_temporary_notification("HAS SIDO DESCUBIERTO", 1.5)
	_teleport_player(last_checkpoint_pos)
	pasco.set_movement_enabled(true)
	spanish_patrol1.reset_patrol()
	spanish_patrol2.reset_patrol()

func _teleport_player(target_position: Vector2) -> void:
	pasco.clear_hide_state()
	pasco.velocity = Vector2.ZERO
	pasco.global_position = target_position

func _on_restart_requested() -> void:
	get_tree().reload_current_scene()

func _on_menu_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
