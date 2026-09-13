extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.combat.silent = true
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/menu-preview.png")
	game.start_run()
	game.set_process(false)
	game.refresh_hud()
	game.spawn_wave()
	for i in range(game.enemies.size()):
		game.enemies[i].pos = game.player + Vector2(80 + i % 3 * 40, (i / 3 - 1) * 54)
		game.enemies[i].skill = 10
	game.aim = Vector2.RIGHT
	game.combat.combo = 2
	game.combat.combo_window = 1
	game.combat.begin_attack()
	game.combat.update(game.combat.swing.duration * 0.42)
	game.refresh_hud()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/game-preview.png")
	for level in [2, 3, 4, 5]:
		game.stage = level
		game.generate_stage()
		game.spawn_wave()
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/stage-%d-preview.png" % level)
	game.combat.reset()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	quit()
