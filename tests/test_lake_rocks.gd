extends SceneTree

class LakeStub extends Node2D:
	var alerts := 0
	var messages := 0
	var impacts := 0
	func add_alert(_amount: float) -> void:
		alerts += 1
	func show_notification(_message: String, _duration: float) -> void:
		messages += 1
	func on_impact() -> void:
		impacts += 1

var failures := 0
var cases := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_checks() -> void:
	for variant in ["Round", "Cluster", "Jagged"]:
		for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			await test_collision(variant, direction, 600.0)
	await test_collision("Jagged", Vector2.RIGHT, 12000.0)
	var level: Node = load("res://scenes/levels/LakeLevel02.tscn").instantiate()
	check(level.get_node("Obstacles").get_child_count() == 15, "Expected all 15 rocks in the editable scene")
	for rock in level.get_node("Obstacles").get_children():
		check(rock is WaterObstacle and rock is StaticBody2D, "Rock must block the boat: " + rock.name)
		check(rock.get_node("CollisionPolygon2D").polygon.size() >= 3, "Missing collision outline")
		check(rock.get_node("Sprite2D").texture != null, "Missing rock PNG")
	level.free()
	print("LAKE_ROCK_TESTS: ", cases, " collision cases; ", failures, " failures")
	quit(1 if failures else 0)

func test_collision(variant: String, direction: Vector2, speed: float) -> void:
	cases += 1
	var fixture := LakeStub.new()
	root.add_child(fixture)
	fixture.add_to_group("lake_level")
	var rock: WaterObstacle = load("res://scenes/objects/LakeRock" + variant + ".tscn").instantiate()
	fixture.add_child(rock)
	var boat := BoatPrototype.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48, 28)
	collision.shape = shape
	boat.add_child(collision)
	boat.position = -direction * 240.0
	fixture.add_child(boat)
	boat.set_physics_process(false)
	boat.impact_received.connect(fixture.on_impact)
	boat.velocidad_actual = 260.0
	await physics_frame
	for step in 40:
		boat.velocity = direction * speed
		boat._move_and_handle_obstacles()
		if fixture.impacts > 0:
			break
		await physics_frame
	check(fixture.impacts == 1, variant + ": missing contact/impact")
	check(boat.position.dot(direction) < 0.0, variant + ": boat passed through the rock")
	check(boat.velocidad_actual < 100.0, variant + ": impact did not reduce speed")
	check(boat.external_force.dot(-direction) > 0.0, variant + ": rebound must point away from the surface")
	check(fixture.alerts == 1 and fixture.messages == 1, variant + ": expected one alert and notification")
	for repeat in 5:
		rock.handle_boat_collision(boat, -direction)
	check(fixture.impacts == 1 and fixture.alerts == 1 and fixture.messages == 1, variant + ": contact spam bypassed cooldown")
	boat.impact_cooldown = 0.0
	rock.handle_boat_collision(boat, -direction)
	check(fixture.impacts == 2 and fixture.alerts == 2, variant + ": a later collision should trigger again")
	fixture.queue_free()
	await process_frame
