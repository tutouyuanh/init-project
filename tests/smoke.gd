extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for hero in range(4):
		game.hero_id = hero
		game.start_run()
		var base_hp: float = game.stat("hp")
		for i in range(100): game.collect(0)
		assert(game.stacks(0) == 100, "Unlimited inventory stacks")
		assert(is_equal_approx(game.stat("rate"), game.Data.HEROES[hero].rate * 3), "Attack speed cap")
		for i in range(120): game.collect(1)
		assert(is_equal_approx(game.stat("crit"), 3), "Multi-critical cap")
		game.collect(14)
		assert(game.revive_charges == 1, "Revive charge")
		assert(game.stat("hp") > base_hp, "Health bonus")
		game.collect(17)
		assert(game.total_items() == 223, "Transformation duplicates an owned item")
	game.start_run()
	for level in range(6):
		game.stage = level
		for seed_value in range(8):
			game.rng.seed = seed_value
			game.generate_stage()
			for room in game.rooms:
				var path: Array = game.route(game.player, room.get_center())
				assert(path[-1].distance_to(room.get_center()) < 1, "Connected room graph")
		game.generate_stage()
		for wave_index in range(3 if level == 5 else 4):
			game.spawn_wave()
			assert(not game.enemies.is_empty(), "Wave spawned")
			for frame in range(10): game._process(0.016)
			game.enemies.clear()
		assert(game.boss_spawned, "Boss follows normal waves")
		game.transition_timer = 0
		game._process(0.016)
		assert(game.portal, "Portal after boss")
	game.start_run()
	game.spawn_wave()
	var enemy_health: float = game.enemies[0].max_hp
	var enemy_attack: float = game.enemies[0].damage
	game.elapsed = 179.99
	game._process(0.02)
	assert(is_equal_approx(game.enemies[0].max_hp, enemy_health * 1.2), "Timed health scaling")
	assert(is_equal_approx(game.enemies[0].damage, enemy_attack * 1.15), "Timed attack scaling")
	game.start_run()
	game.collect(14)
	game.hp = 0
	game._process(0.016)
	assert(game.hp > 0 and game.revive_charges == 0, "Revival consumed once")
	game.hp = 0
	game._process(0.016)
	assert(game.mode == "end", "Defeat screen")
	game.start_run()
	game.finish(true)
	assert(game.mode == "end", "Victory screen")
	print("PASS: four heroes, unlimited stacks, caps, duplication, 48 maps, six stage waves, portals, revival and endings")
	game.queue_free()
	quit()
