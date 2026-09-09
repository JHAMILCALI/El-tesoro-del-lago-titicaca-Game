extends Node2D

enum StoryState {
	START = 0,
	PATROL_1_PASSED = 1,
	HUITA_FOUND = 2,
	TREASURE_QUEST_ACTIVE = 3,
	SECRET_CONVO_HEARD = 4,
	HOUSE_REACHED = 5,
	TREASURE_COLLECTED = 6,
	ESCAPE_STARTED = 7,
	LEVEL_COMPLETED = 8
}

@onready var pasco = $Pasco
@onready var huita = $Huita
@onready var spanish_patrol1 = $SpanishPatrol1
@onready var spanish_patrol2 = $SpanishPatrol2
@onready var spanish_patrol_escape = $SpanishPatrolEscape
@onready var hud = $HUD
@onready var dialogue_box = $DialogueBox
@onready var house = $HouseInterior

@onready var start_checkpoint: Node2D = $Checkpoints/StartCheckpoint
@onready var checkpoint_huita: Node2D = $Checkpoints/CheckpointHuita
@onready var checkpoint_house: Node2D = $Checkpoints/CheckpointHouse
@onready var tutorial_trigger_area: Area2D = $Areas/TutorialTriggerArea
@onready var secret_convo_area: Area2D = $Areas/SecretConvoArea
@onready var final_escape_area: Area2D = $Areas/FinalEscapeArea
@onready var hide_zones: Array[Node] = [
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
var has_heard_secret_convo: bool = false

func _ready() -> void:
	last_checkpoint_pos = start_checkpoint.global_position
	hud.update_objective("Explora el sendero y encuentra a Huita.")
	hud.show_temporary_notification("El camino parece tranquilo, pero hay presencia enemiga cerca.", 3.5)

	hud.restart_requested.connect(_on_restart_requested)
	hud.menu_requested.connect(_on_menu_requested)

	if huita:
		huita.interaction_requested.connect(_on_huita_interaction)
		huita.player_proximity_changed.connect(_on_huita_proximity_changed)

	if spanish_patrol1:
		spanish_patrol1.player_captured.connect(_on_player_captured)
	if spanish_patrol2:
		spanish_patrol2.player_captured.connect(_on_player_captured)
	if spanish_patrol_escape:
		spanish_patrol_escape.player_captured.connect(_on_player_captured)
		spanish_patrol_escape.visible = false
		spanish_patrol_escape.set_physics_process(false)

	if tutorial_trigger_area:
		tutorial_trigger_area.body_entered.connect(_on_tutorial_trigger_entered)

	if secret_convo_area:
		secret_convo_area.body_entered.connect(_on_secret_convo_area_entered)

	if final_escape_area:
		final_escape_area.body_entered.connect(_on_final_escape_area_entered)

	for hide_zone in hide_zones:
		if hide_zone is Area2D:
			(hide_zone as Area2D).body_entered.connect(_on_hide_zone_entered)
			(hide_zone as Area2D).body_exited.connect(_on_hide_zone_exited)

	if house:
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
		story_state = StoryState.PATROL_1_PASSED
	hud.update_objective("Evita a la patrulla y llega hasta Huita.")
	hud.show_temporary_notification("Usa los arbustos para ocultarte o presiona Q para lanzar piedras.", 3.0)

func _on_huita_proximity_changed(is_near: bool) -> void:
	if is_near and story_state <= StoryState.HUITA_FOUND:
		story_state = StoryState.HUITA_FOUND
		hud.update_objective("Habla con Huita.")

func _on_huita_interaction() -> void:
	if story_state >= StoryState.TREASURE_QUEST_ACTIVE:
		return

	story_state = StoryState.TREASURE_QUEST_ACTIVE
	last_checkpoint_pos = checkpoint_huita.global_position

	var lines: Array = [
		{"speaker": "Huita", "text": "Pasco, llegaste."},
		{"speaker": "Pasco", "text": "Los españoles están cerca."},
		{"speaker": "Huita", "text": "Mi familia protegió este secreto durante generaciones."},
		{"speaker": "Huita", "text": "El tesoro está escondido en una antigua casa cerca del lago."},
		{"speaker": "Pasco", "text": "Entonces tengo que recuperar el tesoro."},
		{"speaker": "Huita", "text": "Ten cuidado. No todo enemigo se enfrenta directamente."}
	]

	dialogue_box.start_dialogue(lines)
	dialogue_box.dialogue_finished.connect(func() -> void:
		hud.update_objective("Encuentra la casa abandonada y recupera el tesoro.")
		hud.show_temporary_notification("Checkpoint alcanzado", 2.0)
	, CONNECT_ONE_SHOT)

func _on_secret_convo_area_entered(body: Node2D) -> void:
	if body is Pasco and not has_heard_secret_convo and story_state >= StoryState.TREASURE_QUEST_ACTIVE and story_state < StoryState.SECRET_CONVO_HEARD:
		has_heard_secret_convo = true
		story_state = StoryState.SECRET_CONVO_HEARD

		var lines: Array = [
			{"speaker": "Español 1", "text": "El tesoro debe estar cerca."},
			{"speaker": "Español 2", "text": "Revisaremos la casa antes del amanecer."}
		]

		dialogue_box.start_dialogue(lines)
		dialogue_box.dialogue_finished.connect(func() -> void:
			hud.update_objective("Llega a la casa antes que ellos.")
			hud.show_temporary_notification("Escuchaste la conversación enemiga", 2.5)
		, CONNECT_ONE_SHOT)

func _on_house_door_proximity_changed(is_near: bool) -> void:
	if not is_near:
		hud.hide_interaction_prompt()
		return

	if story_state < StoryState.TREASURE_QUEST_ACTIVE:
		hud.show_interaction_prompt("Habla primero con Huita")
	else:
		hud.show_interaction_prompt("[E] Entrar")

func _on_house_enter_requested() -> void:
	if story_state < StoryState.TREASURE_QUEST_ACTIVE:
		hud.show_temporary_notification("Debes hablar con Huita primero.", 2.0)
		return
	if story_state == StoryState.LEVEL_COMPLETED:
		return

	story_state = StoryState.HOUSE_REACHED if not has_treasure else StoryState.TREASURE_COLLECTED
	last_checkpoint_pos = checkpoint_house.global_position
	_teleport_player(house.get_interior_spawn_position())
	hud.hide_interaction_prompt()
	if has_treasure:
		hud.update_objective("Sal de la casa.")
	else:
		hud.update_objective("Recupera el tesoro.")
		hud.show_temporary_notification("Checkpoint alcanzado", 1.5)

func _on_house_exit_proximity_changed(is_near: bool) -> void:
	if is_near:
		hud.show_interaction_prompt("[E] Salir")
	else:
		hud.hide_interaction_prompt()

func _on_house_exit_requested() -> void:
	if story_state < StoryState.HOUSE_REACHED:
		return

	_teleport_player(house.get_exterior_spawn_position())
	hud.hide_interaction_prompt()

	if has_treasure:
		story_state = StoryState.ESCAPE_STARTED
		hud.update_objective("Escapa de la zona antes de que te encuentren.")
		hud.show_temporary_notification("¡ALERTA ENENIGA! ESCAPA HACIA EL PUNTO SEGURO", 3.5)

		if spanish_patrol_escape:
			spanish_patrol_escape.visible = true
			spanish_patrol_escape.set_physics_process(true)
			spanish_patrol_escape.reset_patrol()
	else:
		story_state = StoryState.TREASURE_QUEST_ACTIVE
		hud.update_objective("Encuentra la casa abandonada y recupera el tesoro.")

func _on_treasure_proximity_changed(is_near: bool) -> void:
	if is_near and not has_treasure:
		hud.show_interaction_prompt("[E] Recoger tesoro")
	else:
		hud.hide_interaction_prompt()

func _on_treasure_requested() -> void:
	if story_state != StoryState.HOUSE_REACHED or has_treasure:
		return

	has_treasure = true
	story_state = StoryState.TREASURE_COLLECTED
	house.collect_treasure()
	last_checkpoint_pos = house.get_treasure_checkpoint_position()
	hud.hide_interaction_prompt()

	var lines: Array = [
		{"speaker": "Pasco", "text": "Lo encontré."}
	]
	dialogue_box.start_dialogue(lines)
	dialogue_box.dialogue_finished.connect(func() -> void:
		hud.update_objective("Sal de la casa.")
		hud.show_temporary_notification("TESORO RECUPERADO", 2.5)
	, CONNECT_ONE_SHOT)

func _on_final_escape_area_entered(body: Node2D) -> void:
	if body is Pasco and story_state == StoryState.ESCAPE_STARTED:
		story_state = StoryState.LEVEL_COMPLETED
		hud.update_objective("Alpha 0.1 completado.")
		hud.show_temporary_notification("Tesoro recuperado. El camino al lago está despejado.", 4.0)
		hud.show_alpha_complete()

func _on_hide_zone_entered(body: Node2D) -> void:
	if body is Pasco:
		body.enter_hide_area()
		hud.show_temporary_notification("OCULTO", 1.5)

func _on_hide_zone_exited(body: Node2D) -> void:
	if body is Pasco:
		body.exit_hide_area()

func _on_player_captured() -> void:
	hud.show_temporary_notification("HAS SIDO DESCUBIERTO", 2.0)
	_teleport_player(last_checkpoint_pos)
	pasco.set_movement_enabled(true)
	if spanish_patrol1:
		spanish_patrol1.reset_patrol()
	if spanish_patrol2:
		spanish_patrol2.reset_patrol()
	if spanish_patrol_escape and spanish_patrol_escape.visible:
		spanish_patrol_escape.reset_patrol()

func _teleport_player(target_position: Vector2) -> void:
	pasco.clear_hide_state()
	pasco.velocity = Vector2.ZERO
	pasco.global_position = target_position

func _on_restart_requested() -> void:
	get_tree().reload_current_scene()

func _on_menu_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
