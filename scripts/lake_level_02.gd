extends Node2D

const SPANISH_ROWBOAT = preload("res://scenes/enemies/SpanishRowboat.tscn")
const CURRENT_VISUAL = preload("res://scenes/objects/LakeCurrentVisual.tscn")
const CAPTURE_SEQUENCE = preload("res://scenes/ui/LakeCaptureSequence.tscn")
const ENEMY_EVENT_TIME := 18.0
const WAVE_TRIGGER_X := [500.0, 2500.0, 4500.0, 6500.0, 7900.0]

@onready var boat: BoatPrototype = $BoatPrototype/Boat
@onready var hud: HUD = $HUD
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var alert_system: AlertSystem = $AlertSystem
@onready var enemy_boats: Array[Node] = [$Enemies/EnemyBoat1, $Enemies/EnemyBoat2, $Enemies/EnemyBoat3]

var elapsed_time := 0.0
var enemies_activated := false
var inside_sacred_zone := false
var pressure_enemies: Dictionary = {}
var level_finished := false
var next_wave_index := 0
var capture_in_progress := false
var active_captor: EnemyBoat

func _ready() -> void:
	add_to_group("lake_level")
	$BoatPrototype/CanvasLayer.hide()
	$BoatPrototype/WaterBackground.hide()
	$BoatPrototype/NorthernShore.hide()
	$BoatPrototype/DepartureDock.hide()
	$BoatPrototype/Obstacles.hide()
	$BoatPrototype/Obstacles.process_mode = Node.PROCESS_MODE_DISABLED
	for old_obstacle in $BoatPrototype/Obstacles.get_children():
		if old_obstacle is CollisionObject2D:
			old_obstacle.collision_layer = 0
	_build_extended_lake()
	hud.show_lake_hud(true)
	hud.update_objective("Cruza el lago y llega al santuario.")
	hud.update_stamina(boat.resistencia, boat.max_stamina)
	hud.update_alert(0.0)
	hud.update_speed(0.0)
	boat.stamina_changed.connect(hud.update_stamina)
	boat.speed_changed.connect(hud.update_speed)
	boat.impact_received.connect(_on_boat_impact)
	alert_system.alert_changed.connect(hud.update_alert)
	$Areas/FinishArea.body_entered.connect(_on_finish_area_body_entered)
	$Areas/SacredZone.body_entered.connect(_on_sacred_zone_body_entered)
	$Areas/SacredZone.body_exited.connect(_on_sacred_zone_body_exited)
	$Areas/OpenWaterZone.body_entered.connect(_on_open_water_entered)
	$Areas/EnemyTrigger.body_entered.connect(_on_enemy_trigger_body_entered)
	hud.restart_requested.connect(func(): get_tree().reload_current_scene())
	hud.menu_requested.connect(func(): get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn"))
	hud.next_level_requested.connect(func(): get_tree().change_scene_to_file("res://scenes/levels/Level03_Transition.tscn"))
	for enemy in enemy_boats:
		enemy.visible = false
		enemy.set_physics_process(false)
		_connect_enemy_capture(enemy)
	_start_intro()

func _process(delta: float) -> void:
	if level_finished or capture_in_progress:
		return
	elapsed_time += delta
	if not enemies_activated and elapsed_time >= ENEMY_EVENT_TIME:
		activate_enemies()
		next_wave_index = maxi(next_wave_index, 1)
	while next_wave_index < WAVE_TRIGGER_X.size() and boat.global_position.x >= WAVE_TRIGGER_X[next_wave_index]:
		if not enemies_activated:
			activate_enemies()
		else:
			_activate_enemy_wave(next_wave_index)
		next_wave_index += 1
	if boat.resistencia <= 0.05 and Input.is_action_pressed("run"):
		show_notification("Necesitas descansar para remar.", 1.5)

func _start_intro() -> void:
	var lines: Array = [
		{"speaker": "NIVEL 2 — TRAVESÍA DEL TITICACA", "text": "Pasco y Huita deben cruzar el lago antes de que los conquistadores los alcancen."},
		{"speaker": "Huita", "text": "La noche nos ayudará a cruzar sin ser vistos."},
		{"speaker": "Pasco", "text": "Debemos proteger el tesoro."},
		{"speaker": "Huita", "text": "El lago tiene muchos caminos, pero solo uno nos llevará al refugio."}
	]
	dialogue_box.start_dialogue(lines)
	dialogue_box.dialogue_finished.connect(func():
		hud.show_temporary_notification("OBJETIVO: Cruza el lago y llega al santuario.", 3.0)
	, CONNECT_ONE_SHOT)

func activate_enemies() -> void:
	enemies_activated = true
	_activate_enemy_wave(0)
	show_notification("Los conquistadores encontraron el rastro.", 3.0)
	hud.update_objective("Escapa por el lago y llega al santuario.")

func _activate_enemy_wave(wave_index: int) -> void:
	var wave_positions: Array[Vector2] = []
	match wave_index:
		0: wave_positions = [Vector2(800, 260), Vector2(1020, -520), Vector2(1250, 240)]
		1: wave_positions = [Vector2(2850, 350), Vector2(3000, -620), Vector2(3240, 130)]
		2: wave_positions = [Vector2(4750, -650), Vector2(4980, 340), Vector2(5200, -140), Vector2(5360, 520)]
		3: wave_positions = [Vector2(6750, 390), Vector2(6930, -610), Vector2(7150, 40), Vector2(7380, -420)]
		4: wave_positions = [Vector2(8000, 310), Vector2(8220, -550), Vector2(8420, 60)]
	if wave_index == 0:
		for i in mini(3, enemy_boats.size()):
			var enemy := enemy_boats[i] as Node2D
			enemy.global_position = wave_positions[i]
			(enemy as EnemyBoat).set_home_position(wave_positions[i])
			enemy.visible = true
			enemy.set_physics_process(true)
	else:
		for position in wave_positions:
			_spawn_enemy_boat(position, 1.0 + wave_index * 0.08)
	if wave_index > 0:
		show_notification("Más barcas enemigas cierran el paso.", 2.2)

func _spawn_enemy_boat(spawn_position: Vector2, speed_multiplier: float) -> void:
	var enemy := SPANISH_ROWBOAT.instantiate() as EnemyBoat
	enemy.position = spawn_position
	enemy.patrol_speed *= speed_multiplier
	enemy.chase_speed *= speed_multiplier
	$Enemies.add_child(enemy)
	enemy_boats.append(enemy)
	_connect_enemy_capture(enemy)

func _connect_enemy_capture(enemy: Node) -> void:
	if enemy is EnemyBoat and not enemy.player_caught.is_connected(_on_player_caught):
		enemy.player_caught.connect(_on_player_caught)

func request_enemy_capture(enemy: EnemyBoat) -> bool:
	if capture_in_progress or level_finished:
		return false
	if active_captor != null and active_captor != enemy:
		return false
	active_captor = enemy
	return true

func _on_player_caught(_caught_enemy: EnemyBoat) -> void:
	if capture_in_progress or level_finished:
		return
	capture_in_progress = true
	boat.set_movement_enabled(false)
	boat.velocity = Vector2.ZERO
	boat.external_force = Vector2.ZERO
	boat.set_physics_process(false)
	boat.set_process_unhandled_input(false)
	hud.hide()
	dialogue_box.hide()
	dialogue_box.set_process_unhandled_input(false)
	for enemy in enemy_boats:
		if enemy is EnemyBoat:
			enemy.velocity = Vector2.ZERO
			enemy.set_physics_process(false)
	var sequence := CAPTURE_SEQUENCE.instantiate()
	add_child(sequence)
	sequence.play()
	await sequence.finished
	get_tree().reload_current_scene()

func _build_extended_lake() -> void:
	# Las rocas están instanciadas en la escena para poder editar sus gráficos y colisiones.
	for current_data in [[Vector2(3500, 30), Vector2(150, -55)], [Vector2(5400, -180), Vector2(-130, 70)], [Vector2(7050, 140), Vector2(170, 25)]]:
		_add_current(current_data[0], current_data[1])

func _add_current(current_position: Vector2, force: Vector2) -> void:
	var current := CurrentZone.new()
	current.position = current_position
	current.force = force
	current.z_index = -1
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(440, 210)
	collision.shape = shape
	current.add_child(collision)
	current.add_child(CURRENT_VISUAL.instantiate())
	add_child(current)

func set_enemy_pressure(enemy: Node, active: bool, distance: float) -> void:
	if inside_sacred_zone:
		active = false
	if active:
		pressure_enemies[enemy] = true
		alert_system.set_value(maxf(alert_system.value, clampf(1.0 - distance / 380.0, 0.0, 0.85)))
	else:
		pressure_enemies.erase(enemy)
	alert_system.danger_sources = pressure_enemies.size()

func add_alert(amount: float) -> void:
	alert_system.add(amount)

func show_notification(message: String, duration: float = 2.0) -> void:
	hud.show_temporary_notification(message, duration)

func _on_boat_impact() -> void:
	show_notification("¡Impacto! La barca pierde velocidad.", 1.4)

func _on_open_water_entered(body: Node2D) -> void:
	if body == boat:
		add_alert(0.1)

func _on_enemy_trigger_body_entered(body: Node2D) -> void:
	if body == boat and not enemies_activated:
		activate_enemies()

func _on_sacred_zone_body_entered(body: Node2D) -> void:
	if body != boat:
		return
	inside_sacred_zone = true
	pressure_enemies.clear()
	alert_system.danger_sources = 0
	alert_system.set_value(alert_system.value * 0.35)
	show_notification("El lago protege su secreto.", 3.0)

func _on_sacred_zone_body_exited(body: Node2D) -> void:
	if body == boat:
		inside_sacred_zone = false

func _on_finish_area_body_entered(body: Node2D) -> void:
	if body != boat or level_finished or capture_in_progress:
		return
	level_finished = true
	boat.set_movement_enabled(false)
	for enemy in enemy_boats:
		enemy.set_physics_process(false)
	var lines: Array = [
		{"speaker": "Huita", "text": "Lo logramos."},
		{"speaker": "Pasco", "text": "El tesoro está a salvo."},
		{"speaker": "Huita", "text": "Pero nuestra historia todavía no termina."}
	]
	dialogue_box.start_dialogue(lines)
	dialogue_box.dialogue_finished.connect(func():
		hud.show_level_complete("EL LAGO ESTÁ A SALVO", "Pasco y Huita han llegado al santuario.\nSu historia continuará muy pronto.")
	, CONNECT_ONE_SHOT)
