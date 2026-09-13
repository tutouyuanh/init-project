extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.combat.silent = true
	game.start_run()
	game.collect(3)
	var damage: float = game.stat("damage")
	for level in range(6):
		assert(game.stage == level)
		assert(game.art.active_stage == level)
		assert(game.art.biomes.resource_path == game.art.STAGE_TEXTURES[level])
		assert(game.art.biomes.get_size() == Vector2(512, 512))
		assert(game.stacks(3) == 1 and game.stat("damage") == damage)
		game.show_stage_clear()
		assert(game.mode == "play", "Cannot advance before clearing boss")
		game.portal = true
		game.show_stage_clear()
		if level == 5:
			assert(game.mode == "end", "Final stage ends the run")
		else:
			assert(game.mode == "chapter")
			var clock_value: float = game.elapsed
			game._process(1.0)
			assert(game.elapsed == clock_value, "Chapter screen freezes combat clock")
			if level == 0 and DisplayServer.get_name() != "headless":
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://tests/chapter-preview.png")
			game.advance_stage()
			assert(game.mode == "play" and not game.portal and game.wave == 0)
	game.show_menu()
	assert(game.art.active_stage == 0)
	game.queue_free()
	await process_frame
	print("PASS: six independent stage resources, sequential chapter transitions, item retention, pause and final victory")
	quit()
