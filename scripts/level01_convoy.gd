extends Node2D

@onready var pasco = $Pasco
@onready var huita = $Huita
@onready var spanish_patrol = $SpanishPatrol
@onready var hud = $HUD
@onready var dialogue_box = $DialogueBox

@onready var start_checkpoint: Node2D = $Checkpoints/StartCheckpoint
@onready var checkpoint_huita: Node2D = $Checkpoints/CheckpointHuita
@onready var checkpoint_secret: Node2D = $Checkpoints/CheckpointSecret
@onready var secret_convo_area: Area2D = $Areas/SecretConvoArea
@onready var final_goal_area: Area2D = $Areas/FinalGoalArea

var last_checkpoint_pos: Vector2
var has_talked_huita: bool = false
var has_heard_secret_convo: bool = false
var is_alpha_completed: bool = false

func _ready() -> void:
	if start_checkpoint:
		last_checkpoint_pos = start_checkpoint.global_position
	else:
		last_checkpoint_pos = pasco.global_position if pasco != null else Vector2(100, 360)

	if hud:
		hud.update_objective("Avanza con cuidado por el camino.")
		hud.restart_requested.connect(_on_restart_requested)
		hud.menu_requested.connect(_on_menu_requested)

	if huita:
		huita.interaction_requested.connect(_on_huita_interaction)

	if spanish_patrol:
		spanish_patrol.player_captured.connect(_on_player_captured)

	if secret_convo_area:
		secret_convo_area.body_entered.connect(_on_secret_convo_area_entered)

	if final_goal_area:
		final_goal_area.body_entered.connect(_on_final_goal_entered)

func _on_huita_interaction() -> void:
	if has_talked_huita or is_alpha_completed:
		return

	has_talked_huita = true
	if checkpoint_huita:
		last_checkpoint_pos = checkpoint_huita.global_position

	var lines = [
		{"speaker": "Huita", "text": "Debemos continuar con cuidado."},
		{"speaker": "Pasco", "text": "Los españoles están cerca."},
		{"speaker": "Huita", "text": "No dejemos que descubran el tesoro."}
	]

	dialogue_box.start_dialogue(lines)
	dialogue_box.dialogue_finished.connect(func():
		hud.update_objective("Acércate sin ser descubierto y escucha la conversación.")
		hud.show_temporary_notification("Checkpoint alcanzado", 2.0)
	, CONNECT_ONE_SHOT)

func _on_secret_convo_area_entered(body: Node2D) -> void:
	if body is Pasco and not has_heard_secret_convo and has_talked_huita and not is_alpha_completed:
		has_heard_secret_convo = true
		if checkpoint_secret:
			last_checkpoint_pos = checkpoint_secret.global_position

		var lines = [
			{"speaker": "Transportador 1", "text": "Los españoles se acercan."},
			{"speaker": "Transportador 2", "text": "Podríamos entregarles el tesoro."},
			{"speaker": "Transportador 1", "text": "A cambio deben permitirnos marcharnos."}
		]

		dialogue_box.start_dialogue(lines)
		dialogue_box.dialogue_finished.connect(func():
			hud.update_objective("Regresa al punto seguro.")
			hud.show_temporary_notification("Checkpoint alcanzado", 2.0)
		, CONNECT_ONE_SHOT)

func _on_final_goal_entered(body: Node2D) -> void:
	if body is Pasco and has_heard_secret_convo and not is_alpha_completed:
		is_alpha_completed = true
		hud.update_objective("Objetivo completado: Alpha 0.1")
		hud.show_temporary_notification("¡Objetivo completado!", 3.0)
		hud.show_alpha_complete()

func _on_player_captured() -> void:
	hud.show_temporary_notification("Has sido descubierto.", 2.5)
	if pasco:
		pasco.global_position = last_checkpoint_pos
		pasco.set_movement_enabled(true)

func _on_restart_requested() -> void:
	get_tree().reload_current_scene()

func _on_menu_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
