extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_checks() -> void:
	var level := load("res://scenes/levels/LakeLevel02.tscn").instantiate() as Node2D
	root.add_child(level)
	level.set_process(false)
	var currents: Array[CurrentZone] = []
	for child in level.get_children():
		if child is CurrentZone:
			currents.append(child)
	check(currents.size() == 4, "Expected all four current zones in level 2")
	for current in currents:
		var visual := current.get_node_or_null("Visual") as Sprite2D
		check(visual != null and visual.texture != null, "Current is missing its PNG sprite")
		check(current.z_index == -1, "Current should render above water and behind obstacles")
		if visual:
			check(absf(wrapf(visual.rotation - current.force.angle(), -PI, PI)) < 0.01, "Current sprite points against its physical force")
			check(visual.scale.x > 0.0 and visual.scale.y > 0.0, "Current sprite has no visible size")
		for current_child in current.get_children():
			check(not current_child is ColorRect, "Current still uses the old color rectangle")
	var boat := level.get_node("BoatPrototype/Boat") as BoatPrototype
	boat.set_physics_process(false)
	boat.global_position = currents[0].global_position
	await physics_frame
	await physics_frame
	check(boat.external_force == currents[0].force, "Current no longer pushes the player boat")
	boat.global_position = Vector2(0, -500)
	await physics_frame
	await physics_frame
	check(boat.external_force == Vector2.ZERO, "Current force did not clear on exit")
	level.queue_free()
	await process_frame
	print("LEVEL02_CURRENT_TESTS: ", currents.size(), " zones; ", failures, " failures")
	quit(1 if failures else 0)
