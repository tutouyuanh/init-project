extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func key(code: Key, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.combat.silent = true
	game.start_run()
	game.spawn_wave()
	game.invulnerable = 20
	# Place enemies in the actual mouse-facing quadrant and let the real process loop run.
	await process_frame
	game.aim = (game.get_global_mouse_position() - game.camera_offset - game.player).normalized()
	for i in range(game.enemies.size()):
		game.enemies[i].pos = game.player + game.aim * (65 + i * 5)
		game.enemies[i].speed = 0
		game.enemies[i].hp = 30
		game.enemies[i].hidden = false
	key(KEY_J, true)
	await create_timer(1.8).timeout
	key(KEY_J, false)
	assert(game.kills > 0, "Held J produces real frame-loop melee kills")
	key(KEY_ESCAPE, true)
	await process_frame
	key(KEY_ESCAPE, false)
	assert(game.paused, "Escape opens pause through input dispatch")
	var clock_value: float = game.elapsed
	await create_timer(0.1).timeout
	assert(game.elapsed == clock_value, "Pause freezes run clock")
	key(KEY_ESCAPE, true)
	await process_frame
	key(KEY_ESCAPE, false)
	assert(not game.paused, "Escape resumes")
	key(KEY_SPACE, true)
	await process_frame
	key(KEY_SPACE, false)
	assert(game.dash_cooldown > 0, "Space input triggers dodge")
	game.combat.reset()
	game.queue_free()
	await process_frame
	print("PASS: held attack input, real-time kills, pause/resume and dodge input")
	quit()
