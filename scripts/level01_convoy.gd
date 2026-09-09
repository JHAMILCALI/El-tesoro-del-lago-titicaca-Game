extends Node2D

enum StoryState {
	START = 0,
	PATROL_1_PASSED = 1,
	HUITA_FOUND = 2,
	TREASURE_QUEST_ACTIVE = 3,
	SECRET_CONVO_HEARD = 4,
	HOUSE_REACHED = 5,
	TREASURE_COLLECTED = 6,
	RETURN_TO_HUITA = 7,
	ESCORT_HUITA_TO_DOCK = 8,
	DOCK_REACHED_BOAT_BOARD = 9,
	LEVEL_COMPLETED = 10
}

@onready var pasco = $Pasco
@onready var huita = $Huita
@onready var spanish_patrol1 = $SpanishPatrol1
@onready var spanish_patrol2 = $SpanishPatrol2
@onready var spanish_patrol_north1 = $SpanishPatrolNorth1
@onready var spanish_patrol_north2 = $SpanishPatrolNorth2
@onready var hud = $HUD
@onready var dialogue_box = $DialogueBox
@onready var house = $HouseInterior
@onready var north_barrier = $Boundaries/RockBarrierNorth

@onready var start_checkpoint: Node2D = $Checkpoints/StartCheckpoint
@onready var checkpoint_huita: Node2D = $Checkpoints/CheckpointHuita
@onready var checkpoint_house: Node2D = $Checkpoints/CheckpointHouse
@onready var checkpoint_escort: Node2D = $Checkpoints/CheckpointEscort
@onready var tutorial_trigger_area: Area2D = $Areas/TutorialTriggerArea
@onready var secret_convo_area: Area2D = $Areas/SecretConvoArea
@onready var dock_area: Area2D = $Areas/DockArea
@onready var hide_zones: Array[Node] = [
	$Areas/HideZone1,
	$Areas/HideZone2,
	$Areas/HideZone3,
	$Areas/HideZone4,
	$Areas/HideZone5,
	$Areas/HideZone6,
	$Areas/HideZoneNorth1,
	$Areas/HideZoneNorth2,
	$Areas/HideZoneNorth3
]

var last_checkpoint_pos: Vector2
var story_state: StoryState = StoryState.START
var has_treasure: bool = false
var has_seen_tutorial: bool = false
var has_heard_secret_convo: bool = false
var is_near_dock_boat: bool = false

func _ready() -> void:
	last_checkpoint_pos = start_checkpoint.global_position
	hud.update_objective("Explora el sendero y encuentra a Huita.")
	hud.show_temporary_notification("El camino parece tranquilo, pero hay presencia enemiga cerca.", 3.5)

	hud.restart_requested.connect(_on_restart_requested)
	hud.menu_requested.connect(_on_menu_requested)

	if huita:
		huita.interaction_requested.connect(_on_huita_interaction)
		huita.player_proximity_changed.connect(_on_huita_proximity_changed)

	for patrol in [spanish_patrol1, spanish_patrol2, spanish_patrol_north1, spanish_patrol_north2]:
		if patrol:
			patrol.player_captured.connect(_on_player_captured)

	if spanish_patrol_north1:
		spanish_patrol_north1.visible = false
		spanish_patrol_north1.set_physics_process(false)
	if spanish_patrol_north2:
		spanish_patrol_north2.visible = false
		spanish_patrol_north2.set_physics_process(false)

	if tutorial_trigger_area:
		tutorial_trigger_area.body_entered.connect(_on_tutorial_trigger_entered)

	if secret_convo_area:
		secret_convo_area.body_entered.connect(_on_secret_convo_area_entered)

	if dock_area:
		dock_area.body_entered.connect(_on_dock_area_entered)
		dock_area.body_exited.connect(_on_dock_area_exited)

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

func _unhandled_input(event: InputEvent) -> void:
	var dist_to_dock := 9999.0
	if dock_area and pasco:
		dist_to_dock = pasco.global_position.distance_to(dock_area.global_position)

	if (is_near_dock_boat or dist_to_dock < 160.0) and story_state >= StoryState.ESCORT_HUITA_TO_DOCK and story_state < StoryState.LEVEL_COMPLETED:
		if event.is_action_pressed("interact") and not event.is_echo():
			get_viewport().set_input_as_handled()
			_on_boat_board_requested()

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
	if story_state == StoryState.RETURN_TO_HUITA:
		_on_huita_second_dialogue()
		return

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

func _on_huita_second_dialogue() -> void:
	story_state = StoryState.ESCORT_HUITA_TO_DOCK
	last_checkpoint_pos = checkpoint_escort.global_position

	# Open North Barrier path upwards to the northern lake!
	if north_barrier:
		north_barrier.queue_free()

	var lines: Array = [
		{"speaker": "Pasco", "text": "¡Huita! Tengo el tesoro con nosotros."},
		{"speaker": "Huita", "text": "¡Excelente, Pasco! Se ha abierto el camino norte hacia el muelle del lago."},
		{"speaker": "Pasco", "text": "Subamos por el camino norte. ¡Te protegeré!"},
		{"speaker": "Huita", "text": "El paso al norte está vigilado por los españoles. ¡Avanza en sigilo!"}
	]

	dialogue_box.start_dialogue(lines)
	dialogue_box.dialogue_finished.connect(func() -> void:
		if huita:
			huita.start_following(pasco)
		hud.update_objective("Escolta a Huita hacia el norte por el muelle del lago.")
		hud.show_temporary_notification("¡CAMINO NORTE ABIERTO! ESCOLTA A HUITA HASTA EL LAGO", 4.0)

		for patrol in [spanish_patrol_north1, spanish_patrol_north2]:
			if patrol:
				patrol.visible = true
				patrol.set_physics_process(true)
				patrol.reset_patrol()
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
	if story_state >= StoryState.ESCORT_HUITA_TO_DOCK:
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
		story_state = StoryState.RETURN_TO_HUITA
		hud.update_objective("Regresa con Huita y avísale que tienes el tesoro.")
		hud.show_temporary_notification("TESORO RECUPERADO. REGRESA CON HUITA", 3.5)
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

func _on_dock_area_entered(body: Node2D) -> void:
	if body is Pasco:
		is_near_dock_boat = true
		if story_state >= StoryState.ESCORT_HUITA_TO_DOCK and story_state < StoryState.LEVEL_COMPLETED:
			story_state = StoryState.DOCK_REACHED_BOAT_BOARD
			hud.update_objective("Sube a la barca y escapa por el lago.")
			hud.show_interaction_prompt("[E] EMBARCAR EN LA BARCA")

func _on_dock_area_exited(body: Node2D) -> void:
	if body is Pasco:
		is_near_dock_boat = false
		hud.hide_interaction_prompt()

func _on_boat_board_requested() -> void:
	if story_state == StoryState.LEVEL_COMPLETED:
		return

	var lines: Array = [
		{"speaker": "Huita", "text": "¡Lo logramos Pasco! ¡El bote nos llevará a través del lago Titicaca!"},
		{"speaker": "Pasco", "text": "¡El tesoro está a salvo y la historia continúa!"}
	]

	dialogue_box.start_dialogue(lines)
	dialogue_box.dialogue_finished.connect(func() -> void:
		story_state = StoryState.LEVEL_COMPLETED
		hud.update_objective("Alpha 0.1 completado.")
		hud.show_temporary_notification("¡NIVEL 1 COMPLETADO! TESORO A SALVO EN EL LAGO TITICACA", 4.5)
		hud.show_alpha_complete()
	, CONNECT_ONE_SHOT)

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

	if story_state >= StoryState.ESCORT_HUITA_TO_DOCK and huita:
		huita.global_position = last_checkpoint_pos + Vector2(-40, 0)
		huita.start_following(pasco)

	for patrol in [spanish_patrol1, spanish_patrol2, spanish_patrol_north1, spanish_patrol_north2]:
		if patrol and patrol.visible:
			patrol.reset_patrol()

func _teleport_player(target_position: Vector2) -> void:
	pasco.clear_hide_state()
	pasco.velocity = Vector2.ZERO
	pasco.global_position = target_position

func _on_restart_requested() -> void:
	get_tree().reload_current_scene()

func _on_menu_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
