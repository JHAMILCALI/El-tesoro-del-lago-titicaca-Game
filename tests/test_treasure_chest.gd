extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_checks() -> void:
	var house := load("res://scenes/levels/HouseInterior.tscn").instantiate() as HouseInterior
	root.add_child(house)
	var chest := house.get_node("Interior/ChestBody") as StaticBody2D
	var area := house.get_node("Interior/TreasureArea") as Area2D
	var sprite := house.get_node("Interior/TreasureArea/TreasureChestSprite") as AnimatedSprite2D
	check(chest != null and chest.collision_layer & 1 != 0, "Chest needs solid world collision")
	check(area != null and area.get_node("CollisionShape2D").shape.radius >= 70.0, "Treasure interaction must remain reachable outside the chest")
	check(sprite.sprite_frames.has_animation(&"collect"), "Chest needs a collection animation")
	check(sprite.sprite_frames.get_frame_texture(&"sparkle", 0).get_size().is_equal_approx(Vector2(627, 627)), "Chest animation must use the improved PNG frames")

	var pasco := load("res://scenes/characters/Pasco.tscn").instantiate() as Pasco
	root.add_child(pasco)
	pasco.set_physics_process(false)
	pasco.global_position = chest.global_position + Vector2(0, 85)
	await physics_frame
	var hit := pasco.move_and_collide(Vector2(0, -100))
	check(hit != null, "Pasco walked through the chest")
	check(pasco.global_position.y > chest.global_position.y + 35.0, "Pasco overlapped the chest base")
	await physics_frame
	check(house.player_near_treasure, "Pasco must be able to interact from outside the chest")
	pasco.global_position = chest.global_position + Vector2(-100, 20)
	await physics_frame
	check(pasco.move_and_collide(Vector2(110, 0)) != null, "Pasco walked through the side of the chest")
	pasco.global_position = chest.global_position + Vector2(0, -100)
	await physics_frame
	check(pasco.move_and_collide(Vector2(0, 120)) != null, "Pasco walked through the back of the chest")

	house.collect_treasure()
	check(not house.treasure_available and not area.monitoring, "Collecting should disable the interaction area")
	await create_timer(0.7).timeout
	check(sprite.animation == &"empty", "Collection animation must end on the empty chest")
	check(chest.get_node("CollisionShape2D").disabled == false, "Empty chest should still block Pasco")
	print("TREASURE_CHEST_TESTS: ", failures, " failures")
	quit(1 if failures else 0)
