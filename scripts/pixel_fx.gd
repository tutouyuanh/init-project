extends RefCounted
# Deterministic, code-native pixel VFX. World-space effects stay at their origin.
var g: Node2D
var dust: Array[Dictionary] = []
var impacts: Array[Dictionary] = []
var ghosts: Array[Dictionary] = []
var walked = 0.0
var ghost_timer = 0.0
var foot = 1.0

func _init(game: Node2D) -> void:
	g = game

func reset() -> void:
	dust.clear()
	impacts.clear()
	ghosts.clear()
	walked = 0
	ghost_timer = 0

func tick(delta: float) -> void:
	ghost_timer -= delta
	for group in [dust, impacts, ghosts]:
		for effect in group: effect.life -= delta
	for p in dust:
		p.pos += p.vel * delta
		p.vel *= exp(-delta * 4)
	dust = dust.filter(func(p): return p.life > 0)
	impacts = impacts.filter(func(p): return p.life > 0)
	ghosts = ghosts.filter(func(p): return p.life > 0)

func motion(before: Vector2, after: Vector2) -> void:
	var moved = after - before
	if moved.length() < 0.1: return
	walked += moved.length()
	if walked >= 24:
		walked = fmod(walked, 24)
		foot *= -1
		var origin = after + Vector2(foot * 10, 6)
		for i in range(5):
			dust.append({"pos": origin + Vector2(i * 3 - 6, 0), "vel": -moved.normalized() * (25 + i * 7) + Vector2((i - 2) * 7, -14), "life": 0.42, "max": 0.42})
	if g.dash_timer > 0 and ghost_timer <= 0:
		ghost_timer = 0.035
		ghosts.append({"pos": after, "life": 0.24, "max": 0.24, "frame": int(g.combat.walk_clock / 1.7) % 4, "left": g.aim.x < 0})

func hit(pos: Vector2, heavy: bool) -> void:
	impacts.append({"pos": pos + Vector2(0, -28), "life": 0.42 if heavy else 0.28, "max": 0.42 if heavy else 0.28, "heavy": heavy})
	if impacts.size() > 32: impacts.pop_front()

func draw_ground() -> void:
	for ghost in ghosts:
		g.art.draw_hero(ghost.pos, ghost.frame, ghost.left, Color(0.5, 0.9, 1.0, ghost.life / ghost.max * 0.48))
	for p in dust:
		var t: float = 1 - p.life / p.max
		var size = 6 + int(t * 3) * 3
		var color = Color("9bd0d2") if g.stage == 0 else Color("d1b88d")
		color.a = p.life / p.max * 0.75
		g.draw_rect(Rect2(p.pos.snapped(Vector2(3, 3)), Vector2(size, size)), color)

func draw_hits() -> void:
	for hit in impacts:
		var p: float = 1 - hit.life / hit.max
		var radius: float = (64 if hit.heavy else 42) * (0.55 + p * 0.6)
		var origin: Vector2 = hit.pos.snapped(Vector2(3, 3))
		var color = Color("fff5cb") if p < 0.27 else Color("ffb844")
		color.a = minf(1, hit.life / hit.max * 2)
		var points = PackedVector2Array()
		for i in range(16):
			points.append((origin + Vector2.from_angle(i * TAU / 16) * radius * (1.0 if i % 2 == 0 else 0.22)).snapped(Vector2(3, 3)))
		g.draw_colored_polygon(points, Color("57382c"))
		for i in range(points.size()): points[i] = origin + (points[i] - origin) * 0.78
		g.draw_colored_polygon(points, color)
		if hit.heavy:
			for i in range(12):
				var pos = (origin + Vector2.from_angle(i * TAU / 12) * radius * (1 + p)).snapped(Vector2(3, 3))
				g.draw_rect(Rect2(pos, Vector2(6, 6)), color)
