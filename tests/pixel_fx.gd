extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.combat.silent = true
	game.start_run()
	var fx: RefCounted = game.fx
	fx.motion(game.player, game.player)
	assert(fx.dust.is_empty(), "No dust at rest")
	fx.motion(game.player, game.player + Vector2(28, 0))
	assert(fx.dust.size() == 5, "Footstep dust emitted by traveled distance")
	var origin: Vector2 = fx.dust[0].pos
	game.player += Vector2(60, 0)
	assert(fx.dust[0].pos == origin, "Dust stays in world space")
	game.dash_timer = 0.18
	fx.motion(game.player, game.player + Vector2(20, 0))
	assert(fx.ghosts.size() == 1, "Dodge emits character afterimage")
	game.combat.impact(game.player, true)
	assert(fx.impacts.size() == 1 and fx.impacts[0].heavy, "Heavy hit emits pixel impact")
	assert(game.art.minions.walk.get_size() == Vector2(640, 80), "Eight-frame SpriteCook animation loaded")
	assert(game.art.heroes.get_size().x >= 1024, "Generated hero walk sheet loaded")
	fx.tick(1.0)
	assert(fx.dust.is_empty() and fx.ghosts.is_empty() and fx.impacts.is_empty(), "Effects expire")
	game.generate_stage()
	assert(fx.dust.is_empty(), "Stage change resets FX")
	game.queue_free()
	await process_frame
	print("PASS: pixel footsteps, world-space particles, dodge ghosts, heavy impacts, sprite sheets and effect lifetime")
	quit()
