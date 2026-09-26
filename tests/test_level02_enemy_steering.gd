extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_checks() -> void:
	var player := Node2D.new()
	player.add_to_group("player")
	root.add_child(player)
	var enemy := load("res://scenes/enemies/SpanishRowboat.tscn").instantiate() as EnemyBoat
	root.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.player = player
	enemy.state = EnemyBoat.State.CHASE
	await physics_frame
	_check_threshold_steering(enemy, Vector2.LEFT, enemy.side_clearance, "lateral")

	var leader := load("res://scenes/enemies/SpanishRowboat.tscn").instantiate() as EnemyBoat
	root.add_child(leader)
	leader.set_physics_process(false)
	leader.player = player
	leader.state = EnemyBoat.State.CHASE
	leader.global_position = Vector2(50, 0)
	enemy.velocity = Vector2.ZERO
	enemy.rotation = 0.0
	_check_threshold_steering(enemy, Vector2.RIGHT, enemy.follow_distance, "escolta")

	root.remove_child(enemy)
	root.remove_child(leader)
	root.remove_child(player)
	enemy.free()
	leader.free()
	player.free()
	print("LEVEL02_ENEMY_STEERING_TESTS: ", failures, " failures")
	quit(1 if failures else 0)

func _check_threshold_steering(enemy: EnemyBoat, side: Vector2, threshold: float, case_name: String) -> void:
	var previous_velocity := Vector2.ZERO
	for frame in 90:
		enemy.global_position = side * (threshold + (1.0 if frame % 2 == 0 else -1.0))
		var old_rotation := enemy.rotation
		enemy._chase_player(enemy.global_position.length(), 1.0 / 60.0)
		var turn := absf(wrapf(enemy.rotation - old_rotation, -PI, PI))
		check(turn < deg_to_rad(10.0), case_name + " turned too sharply at frame " + str(frame))
		if frame > 10 and previous_velocity.length_squared() > 25.0 and enemy.velocity.length_squared() > 25.0:
			check(previous_velocity.dot(enemy.velocity) > 0.0, case_name + " reversed direction at frame " + str(frame))
		previous_velocity = enemy.velocity
