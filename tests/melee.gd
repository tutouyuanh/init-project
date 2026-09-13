extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_run()
	game.spawn_wave()
	var first: Dictionary = game.enemies[0]
	var rear: Dictionary = game.enemies[1]
	var far: Dictionary = game.enemies[2]
	first.pos = game.player + Vector2(75, 0)
	rear.pos = game.player + Vector2(-75, 0)
	far.pos = game.player + Vector2(175, 0)
	for enemy in game.enemies:
		enemy.hp = 1000.0
		enemy.max_hp = 1000.0
		enemy.speed = 0.0
		enemy.skill = 100.0
	game.aim = Vector2.RIGHT
	var combat: RefCounted = game.combat
	assert(combat.begin_attack(false), "Light attack accepted")
	combat.update(combat.swing.windup * 0.5)
	assert(first.hp == 1000.0, "Windup cannot deal damage")
	combat.update(combat.swing.windup)
	assert(first.hp < 1000.0, "Front target in melee reach damaged")
	assert(rear.hp == 1000.0, "Normal swing does not hit behind player")
	assert(far.hp == 1000.0, "No ranged damage")
	var after_first_hit: float = first.hp
	combat.update(0.01)
	assert(first.hp == after_first_hit, "One hit per target per swing")
	assert(first.stun > 0 and first.knockback.length() > 0, "Hit causes stun and knockback")
	assert(combat.hit_stop > 0 and combat.shake > 0 and not combat.sparks.is_empty(), "Hit stop, shake and particles")
	for step in range(2):
		combat.swing.clear()
		game.attack_timer = 0
		assert(combat.begin_attack(false))
	assert(combat.combo == 3 and combat.swing.damage > game.stat("damage") * 1.5, "Combo finisher")
	combat.swing.clear()
	game.attack_timer = 0
	assert(combat.begin_attack(true), "Heavy accepted")
	assert(combat.swing.damage > game.stat("damage") * 2.5, "Heavy damage")
	combat.dodge(Vector2.LEFT)
	assert(combat.swing.is_empty() and game.invulnerable > 0, "Dodge cancels attack and grants invulnerability")
	assert(combat.dash_direction == Vector2.LEFT, "Dodge direction retained")
	game.dash_timer = 0
	assert(not combat.begin_attack(true), "Heavy cooldown survives dodge cancel")
	combat.reset()
	game.attack_timer = 0
	game.aim = Vector2.RIGHT
	assert(combat.begin_attack())
	# Construct a wall between two reachable islands; weapon must not hit through it.
	game.rooms.clear()
	game.rooms.append(Rect2(0, 0, 90, 180))
	game.rooms.append(Rect2(110, 0, 90, 180))
	game.corridors.clear()
	game.player = Vector2(65, 90)
	assert(not combat.in_arc(Vector2(135, 90), 18), "Melee blocked by wall")
	game.start_run()
	game.spawn_wave()
	game.enemies.resize(1)
	first = game.enemies[0]
	first.pos = game.player + Vector2(50, 0)
	first.skill = 0
	first.speed = 0
	var initial_hp: float = game.hp
	combat.update_enemies(0.01)
	assert(first.windup > 0 and game.hp == initial_hp, "Enemy telegraphs before damage")
	game.player += Vector2(-110, 0)
	combat.update_enemies(0.6)
	assert(game.hp == initial_hp, "Walking out of telegraph avoids hit")
	game.combat.reset()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("PASS: melee windup, range, facing, single hit, combo, heavy cooldown, dodge cancel, walls and enemy telegraphs")
	quit()
