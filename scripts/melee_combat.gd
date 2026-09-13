extends RefCounted
# Combat uses explicit windup / active / recovery phases. No player projectiles.
var silent = false
var g: Node2D
var swing: Dictionary = {}
var combo = 0
var combo_window = 0.0
var heavy_cooldown = 0.0
var hit_stop = 0.0
var shake = 0.0
var flash = 0.0
var sparks: Array[Dictionary] = []
var dash_direction = Vector2.RIGHT
var moving = false
var walk_clock = 0.0
var sfx: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_index = 0
var audio_rng = RandomNumberGenerator.new()

func _init(game: Node2D) -> void:
	g = game
	audio_rng.seed = 831
	for kind in ["swing", "hit", "heavy", "hurt", "dash"]:
		sfx[kind] = make_sound(kind)
	for i in range(8):
		var voice = AudioStreamPlayer.new()
		voice.volume_db = -14
		g.add_child(voice)
		voices.append(voice)

func reset() -> void:
	swing.clear()
	combo = 0
	combo_window = 0
	heavy_cooldown = 0
	hit_stop = 0
	shake = 0
	flash = 0
	sparks.clear()
	moving = false
	for voice in voices: voice.stop()

func play(kind: String) -> void:
	if silent or DisplayServer.get_name() == "headless": return
	var voice = voices[voice_index % voices.size()]
	voice_index += 1
	voice.stream = sfx[kind]
	voice.pitch_scale = audio_rng.randf_range(0.93, 1.06)
	voice.play()

func make_sound(kind: String) -> AudioStreamWAV:
	var duration = 0.24 if kind == "heavy" else 0.13
	var data = PackedByteArray()
	var samples = int(22050 * duration)
	data.resize(samples * 2)
	var low_noise = 0.0
	for i in range(samples):
		var t = float(i) / 22050
		var p = float(i) / samples
		low_noise = lerpf(low_noise, audio_rng.randf_range(-1, 1), 0.22)
		var value = 0.0
		if kind == "swing" or kind == "dash":
			value = low_noise * sin(PI * p) * (1 - p) * 1.5
		else:
			var frequency = 70.0 if kind == "heavy" else (115.0 if kind == "hit" else 85.0)
			value = (sin(TAU * (frequency * t - 100 * t * t)) * 0.6 + low_noise * 0.8) * pow(1 - p, 3)
		data.encode_s16(i * 2, int(clampf(value, -1, 1) * 26000))
	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	sound.data = data
	return sound

func presentation_tick(delta: float) -> bool:
	shake = move_toward(shake, 0, delta * 42)
	flash = move_toward(flash, 0, delta * 3)
	for p in sparks:
		p.life -= delta
		p.pos += p.vel * delta
		p.vel *= exp(-delta * 6)
	sparks = sparks.filter(func(p): return p.life > 0)
	if hit_stop > 0:
		hit_stop -= delta
		return true
	return false

func camera_shake() -> Vector2:
	return Vector2(sin(Time.get_ticks_msec() * 0.077), cos(Time.get_ticks_msec() * 0.091)) * shake

func begin_attack(heavy: bool = false) -> bool:
	if not swing.is_empty() or g.attack_timer > 0 or g.dash_timer > 0: return false
	if heavy and heavy_cooldown > 0: return false
	if combo_window <= 0: combo = 0
	combo = 0 if heavy else combo % 3 + 1
	var rate: float = g.stat("rate")
	var duration = (1.55 if heavy else 1.0) / rate
	var reach: float = [114.0, 122.0, 120.0, 128.0][g.hero_id]
	var angle = 1.15
	var damage = 1.0
	if g.hero_id == 3: angle = 0.8; damage = 1.15
	if combo == 2: damage = 1.18
	if combo == 3: reach += 22; angle = 2.5; damage = 1.65
	if heavy: reach += 48; angle = PI; damage = 2.8; heavy_cooldown = 2.8
	swing = {"time": 0.0, "duration": duration, "windup": duration * (0.37 if heavy else 0.18), "end": duration * 0.70, "aim": g.aim, "reach": reach, "angle": angle, "damage": g.stat("damage") * damage, "heavy": heavy, "combo": combo, "hits": [], "sounded": false}
	g.attack_timer = duration
	combo_window = duration + 0.75
	return true

func dodge(direction: Vector2) -> void:
	if g.dash_cooldown > 0: return
	dash_direction = direction.normalized() if direction.length_squared() > 0 else g.aim
	g.dash_timer = 0.5 if g.stacks(15) > 0 else 0.19
	g.invulnerable = maxf(g.invulnerable, g.dash_timer + 0.08)
	g.dash_cooldown = 1.6
	# Dodge cancels recovery and windup, never refunds the heavy cooldown.
	swing.clear()
	g.attack_timer = 0
	play("dash")

func update(delta: float) -> void:
	combo_window -= delta
	heavy_cooldown -= delta
	if not swing.is_empty():
		swing.time += delta
		if swing.time >= swing.windup and not swing.sounded:
			swing.sounded = true
			play("heavy" if swing.heavy else "swing")
			g.player = g.move_actor(g.player, swing.aim * (21 if swing.heavy else 12))
		if swing.time >= swing.windup and swing.time <= swing.end:
			for enemy in g.enemies:
				if enemy.hp <= 0 or swing.hits.has(enemy.id): continue
				if in_arc(enemy.pos, 35 if enemy.boss else 18):
					swing.hits.append(enemy.id)
					g.hit_enemy(enemy, swing.damage)
					var strength = (410 if swing.heavy else (300 if swing.combo == 3 else 170))
					enemy.knockback = g.player.direction_to(enemy.pos) * strength * (0.28 if enemy.boss else 1)
					enemy.stun = 0.12 if enemy.boss else (0.48 if swing.heavy else 0.24)
					if not enemy.boss: enemy.windup = 0.0
					impact(enemy.pos, swing.heavy or swing.combo == 3)
		if swing.time >= swing.duration: swing.clear()
	update_enemies(delta)

func in_arc(pos: Vector2, radius: float) -> bool:
	if swing.is_empty(): return false
	var relative: Vector2 = pos - g.player
	if relative.length() > swing.reach + radius: return false
	if not g.visible_path(g.player, pos): return false
	return relative.length() < 22 or absf(swing.aim.angle_to(relative)) <= swing.angle

func update_enemies(delta: float) -> void:
	for enemy in g.enemies:
		if enemy.hp <= 0: continue
		enemy.hit -= delta
		enemy.stun -= delta
		enemy.skill -= delta
		enemy.path_timer -= delta
		if enemy.burn > 0:
			enemy.burn -= delta
			enemy.hp -= g.stat("damage") * minf(3, 0.25 * g.stacks(13)) * delta
		enemy.pos = g.move_actor(enemy.pos, enemy.knockback * delta)
		enemy.knockback *= exp(-delta * 10)
		if enemy.stun > 0: continue
		if enemy.windup > 0:
			enemy.windup -= delta
			if enemy.windup <= 0:
				resolve_enemy_attack(enemy)
			continue
		var distance: float = enemy.pos.distance_to(g.player)
		if enemy.skill <= 0 and distance < (240 if enemy.boss else 66) and g.visible_path(enemy.pos, g.player):
			enemy.windup = (0.9 if enemy.boss else 0.48)
			enemy.windup_max = enemy.windup
			enemy.target = g.player
			enemy.attack_origin = enemy.pos
			enemy.skill = 2.4 if enemy.boss else 1.3
			continue
		if enemy.path_timer <= 0:
			enemy.path = g.route(enemy.pos, g.player)
			enemy.path_timer = g.rng.randf_range(0.7, 1.2)
		if distance > (95 if enemy.boss else 43) and not enemy.path.is_empty():
			var target: Vector2 = enemy.path[0]
			if enemy.pos.distance_to(target) < 18: enemy.path.pop_front()
			else: enemy.pos = g.move_actor(enemy.pos, enemy.pos.direction_to(target) * enemy.speed * delta)
		# A small separation force keeps a group readable instead of overlapping into one enemy.
		for other in g.enemies:
			if other.id == enemy.id: continue
			var between: Vector2 = enemy.pos - other.pos
			if between.length_squared() > 0.01 and between.length() < 35:
				enemy.pos = g.move_actor(enemy.pos, between.normalized() * delta * 26)

func resolve_enemy_attack(enemy: Dictionary) -> void:
	var center: Vector2 = enemy.target
	var radius = 105.0 if enemy.boss else 42.0
	if enemy.boss and g.stage == 2:
		enemy.pos = g.move_actor(enemy.pos, enemy.pos.direction_to(center) * minf(160, enemy.pos.distance_to(center)))
		center = enemy.pos
	if g.player.distance_to(center) < radius and g.visible_path(enemy.attack_origin, g.player): g.hurt(enemy.damage)
	g.effects.append({"pos": center, "life": 0.3, "max": 0.3, "text": "", "color": Color("f38975"), "ring": radius})
	burst(center, Color("f38975"), 12 if enemy.boss else 5)
	if enemy.boss: shake = maxf(shake, 5)

func impact(pos: Vector2, heavy: bool) -> void:
	g.fx.hit(pos, heavy)
	hit_stop = maxf(hit_stop, 0.075 if heavy else 0.035)
	shake = maxf(shake, 8 if heavy else 3.5)
	flash = 0.13 if heavy else 0.045
	burst(pos, Color("ffe3a1"), 18 if heavy else 9)
	play("hit")

func burst(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		var angle = TAU * float(i) / count + g.rng.randf_range(-0.25, 0.25)
		sparks.append({"pos": pos, "vel": Vector2.from_angle(angle) * g.rng.randf_range(100, 340), "life": g.rng.randf_range(0.16, 0.4), "color": color})

func draw_warnings() -> void:
	for enemy in g.enemies:
		if enemy.windup <= 0: continue
		var radius = 105.0 if enemy.boss else 42.0
		var progress: float = 1 - enemy.windup / enemy.windup_max
		g.draw_circle(enemy.target, radius, Color(0.9, 0.18, 0.1, 0.10 + progress * 0.16))
		g.draw_arc(enemy.target, radius, 0, TAU, 48, Color("f08c72"), 2)
		g.draw_arc(enemy.target, radius * progress, 0, TAU, 48, Color("ffc59a"), 2)

func draw_swing() -> void:
	if swing.is_empty():
		var rest: Vector2 = g.player + Vector2(22 if g.aim.x > 0 else -22, -28)
		g.draw_line(rest + Vector2(-12, 31), rest + Vector2(12, -38), Color("6d4430"), 7, true)
		g.draw_line(rest + Vector2(-12, 31), rest + Vector2(12, -38), Color("efc879"), 3, true)
		return
	var p: float = clampf((swing.time - swing.windup) / (swing.end - swing.windup), 0, 1)
	var direction: float = swing.aim.angle()
	var reversed = swing.combo == 2
	var start: float = direction - swing.angle * (1 if not reversed else -1)
	var end: float = direction + swing.angle * (1 if not reversed else -1)
	var weapon_angle = lerp_angle(start, direction - 0.65, 0.1) if swing.time < swing.windup else lerpf(start, end, p)
	if swing.time >= swing.windup and swing.time <= swing.end:
		var points = PackedVector2Array()
		var tail = maxf(0, p - 0.70)
		for i in range(25):
			var a = lerpf(start, end, lerpf(tail, p, i / 24.0))
			points.append(g.player + Vector2.from_angle(a) * swing.reach)
		for i in range(24, -1, -1):
			var a = lerpf(start, end, lerpf(tail, p, i / 24.0))
			points.append(g.player + Vector2.from_angle(a) * (swing.reach - 24))
		if p > 0.01:
			g.draw_colored_polygon(points, Color(1, 0.69, 0.18, 0.90))
			g.draw_polyline(PackedVector2Array(Array(points).slice(0, 25)), Color("fff9df"), 7, false)
	var v = Vector2.from_angle(weapon_angle)
	var grip: Vector2 = g.player + Vector2(0, -18)
	g.draw_line(grip - v * 24, grip + v * (swing.reach - 12), Color("50362c"), 9, true)
	g.draw_line(grip - v * 24, grip + v * (swing.reach - 12), Color("e8bb65"), 5, true)
	g.draw_line(grip + v * (swing.reach - 32), grip + v * (swing.reach - 12), Color("fff0bf"), 7, true)
	if g.hero_id == 1:
		for i in range(-2, 3):
			var tip: Vector2 = grip + v * (swing.reach - 18) + v.orthogonal() * i * 8
			g.draw_line(tip - v * 9, tip + v * 9, Color("d3d6d2"), 4, true)
	if g.hero_id == 3:
		g.draw_line(grip + v * 12, grip + v * (swing.reach - 8), Color("dbffff"), 7, true)

func draw_particles() -> void:
	for p in sparks:
		g.draw_line(p.pos, p.pos - p.vel.normalized() * 9, Color(p.color, minf(1, p.life * 5)), 5, false)
