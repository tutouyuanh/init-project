extends RefCounted
var g: Node2D
const STAGE_TEXTURES = [
	"res://assets/stages/01_dragon_palace.tres",
	"res://assets/stages/02_daughter_kingdom.tres",
	"res://assets/stages/03_flaming_mountain.tres",
	"res://assets/stages/04_heavenly_palace.tres",
	"res://assets/stages/05_spider_cave.tres",
	"res://assets/stages/06_thunder_temple.tres"
]
var biomes: Texture2D
var active_stage = -1
var actors: Texture2D
var heroes: Texture2D
var minions: Dictionary = {}

func _init(game: Node2D) -> void:
	g = game
	load_stage(0)
	actors = load("res://assets/art/characters.png")
	heroes = load("res://assets/art/heroes_pixel_walk.png")
	for animation in ["idle", "walk", "attack"]:
		minions[animation] = load("res://assets/spritecook/" + animation + "_sheet.png")

func load_stage(index: int) -> void:
	if active_stage == index: return
	active_stage = index
	biomes = load(STAGE_TEXTURES[index])

func biome_region() -> Rect2:
	return Rect2(Vector2.ZERO, biomes.get_size())

func menu_background() -> void:
	g.draw_texture_rect_region(biomes, Rect2(0, 0, 1440, 900), biome_region(), Color(0.42, 0.5, 0.56))
	g.draw_rect(Rect2(0, 0, 1440, 900), Color(0.025, 0.05, 0.075, 0.72))

func environment() -> void:
	var source = biome_region()
	var tint: Color = g.Data.STAGES[g.stage][3]
	# Slow-moving lower plane gives the playable platforms visual height.
	var shift: Vector2 = g.camera_offset * 0.23
	for x in range(-1, 3):
		for y in range(-1, 3):
			var pos = Vector2(x * 1800, y * 1800) + Vector2(fposmod(shift.x, 1800), fposmod(shift.y, 1800))
			g.draw_texture_rect_region(biomes, Rect2(pos, Vector2(1800, 1800)), source, Color(0.42, 0.51, 0.58))
	g.draw_rect(Rect2(0, 0, 1440, 900), Color(tint.darkened(0.4), 0.20))
	g.draw_set_transform(g.camera_offset)
	# All elevation shadows are drawn before surfaces, keeping bridges open.
	for r in g.rooms:
		g.draw_style_box(platform_style(Color("101c25"), tint.darkened(0.45)), Rect2(r.position + Vector2(0, 22), r.size))
	for c in g.corridors:
		g.draw_rect(Rect2(c.position + Vector2(0, 16), c.size), Color("15252c"))
	for c in g.corridors:
		g.draw_texture_rect_region(biomes, c, Rect2(source.position + source.size * 0.35, source.size * 0.30), Color(0.82, 0.87, 0.88))
		# Subtle stone seams follow the bridge axis.
		if c.size.x > c.size.y:
			for x in range(int(c.position.x), int(c.end.x), 44):
				g.draw_line(Vector2(x, c.position.y + 8), Vector2(x, c.end.y - 8), Color(0.1, 0.15, 0.18, 0.3), 2)
		else:
			for y in range(int(c.position.y), int(c.end.y), 44):
				g.draw_line(Vector2(c.position.x + 8, y), Vector2(c.end.x - 8, y), Color(0.1, 0.15, 0.18, 0.3), 2)
	for r in g.rooms:
		g.draw_rect(r.grow(3), tint.lightened(0.14))
		g.draw_texture_rect_region(biomes, r, Rect2(source.position + source.size * 0.25, source.size * 0.50), Color(0.88, 0.91, 0.92))
		# Tile joints and a central inlaid seal help communicate a walkable plane.
		g.draw_arc(r.get_center(), 60, 0, TAU, 64, Color(0.84, 0.8, 0.53, 0.20), 2)
		g.draw_arc(r.get_center(), 67, 0, TAU, 64, Color(0.84, 0.8, 0.53, 0.12), 1)
		for corner in [Vector2(20, 20), Vector2(r.size.x - 20, 20), Vector2(20, r.size.y - 20), r.size - Vector2(20, 20)]:
			var pos: Vector2 = r.position + corner
			g.draw_circle(pos, 17, Color(0.04, 0.08, 0.12, 0.45))
			g.draw_line(pos, pos + Vector2(0, -32), tint.lightened(0.22), 11, true)
			g.draw_circle(pos + Vector2(0, -35), 6, Color("b1e3d4") if g.stage == 0 else g.GOLD)
			g.draw_circle(pos + Vector2(0, -35), 19, Color(0.65, 0.85, 0.73, 0.08))

func platform_style(color: Color, edge: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	return style

func draw_actor(pos: Vector2, index: int, size: Vector2, facing_left: bool, brightness: float = 1.0, lean: float = 0, bob: float = 0) -> void:
	var cell = actors.get_size() / Vector2(4, 2)
	var source = Rect2(Vector2(index % 4, index / 4) * cell + Vector2(3, 3), cell - Vector2(6, 6))
	g.draw_set_transform(g.camera_offset + pos, 0, Vector2(1, 0.35))
	g.draw_circle(Vector2(0, 2), size.x * 0.28, Color(0.02, 0.03, 0.04, 0.45))
	g.draw_set_transform(g.camera_offset + pos + Vector2(0, bob), lean, Vector2(-1 if facing_left else 1, 1))
	g.draw_texture_rect_region(actors, Rect2(-size.x * 0.5, -size.y * 0.90, size.x, size.y), source, Color(brightness, brightness, brightness))
	g.draw_set_transform(g.camera_offset)

func characters() -> void:
	var sorted: Array = g.enemies.duplicate()
	sorted.append({"player": true, "pos": g.player})
	sorted.sort_custom(func(a, b): return a.pos.y < b.pos.y)
	for actor in sorted:
		if actor.get("player", false):
			var lean = 0.0
			if not g.combat.swing.is_empty():
				lean = sin(g.combat.swing.time / g.combat.swing.duration * PI) * 0.18 * (1 if g.aim.x >= 0 else -1)
			var bob = sin(g.combat.walk_clock) * 2.5 if g.combat.moving else sin(g.elapsed * 2) * 0.6
			if g.dash_timer > 0:
				g.draw_line(g.player - g.combat.dash_direction * 85, g.player, Color(0.73, 0.92, 0.93, 0.45), 18, true)
				bob -= 12
			var frame = int(g.combat.walk_clock / 1.7) % 4 if g.combat.moving else 0
			var bright = 1.7 if g.invulnerable > 0 and int(g.elapsed * 14) % 2 == 0 else 1.0
			draw_hero(g.player + Vector2(0, bob), frame, g.aim.x < 0, Color(bright, bright, bright), lean)
			g.draw_arc(g.player + Vector2(0, 7), 27, 0.1, PI - 0.1, 32, Color("6cd4b0"), 2)
		else:
			if actor.hidden and actor.pos.distance_to(g.player) > 145 + g.stacks(12) * 130: continue
			var sprite: int = [4, 6, 5, 4, 6, 7][g.stage]
			if actor.boss: sprite = [7, 6, 5, 7, 6, 7][g.stage]
			var size = Vector2(125, 158) if actor.boss else Vector2(75, 88)
			var lean = sin(g.elapsed * 8 + actor.id) * 0.03
			if actor.windup > 0: lean = -0.10
			if actor.boss:
				draw_actor(actor.pos, sprite, size, actor.pos.x > g.player.x, 2.5 if actor.hit > 0 else 1.0, lean)
			else:
				var animation = "attack" if actor.windup > 0 else ("walk" if actor.pos.distance_to(g.player) > 43 and actor.stun <= 0 else "idle")
				var frame = int(g.elapsed * 10 + actor.id) % 8
				if actor.windup > 0: frame = mini(7, int((1 - actor.windup / actor.windup_max) * 8))
				g.draw_set_transform(g.camera_offset + actor.pos, 0, Vector2(-1 if actor.pos.x > g.player.x else 1, 1))
				var bright = 2.4 if actor.hit > 0 else 1.0
				g.draw_texture_rect_region(minions[animation], Rect2(-48, -86, 96, 96), Rect2(frame * 80, 0, 80, 80), Color(bright, bright, bright))
				g.draw_set_transform(g.camera_offset)
			var width = 90.0 if actor.boss else 38.0
			g.draw_rect(Rect2(actor.pos + Vector2(-width / 2, 15), Vector2(width, 4)), Color("18202a"))
			g.draw_rect(Rect2(actor.pos + Vector2(-width / 2, 15), Vector2(width * maxf(0, actor.hp / actor.max_hp), 4)), g.GOLD if actor.boss else Color("e38675"))
			if actor.boss: g.draw_string(g.font, actor.pos + Vector2(-55, -153), g.Data.STAGES[g.stage][2], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, g.GOLD)

func atmosphere() -> void:
	g.draw_set_transform(Vector2.ZERO)
	for i in range(35):
		var pos = Vector2(fposmod(i * 197.3 + g.elapsed * (5 if g.stage == 0 else 12) + g.camera_offset.x * 0.4, 1440), fposmod(i * 113.7 - g.elapsed * 13 + g.camera_offset.y * 0.4, 900))
		var color = Color(0.6, 0.88, 0.96, 0.28) if g.stage == 0 else Color(g.GOLD, 0.24)
		g.draw_circle(pos, 1.3 + sin(i * 3) * 0.6, color)
	# A restrained veil at the edges keeps contrast at the player without hiding the backdrop.
	for i in range(5):
		g.draw_rect(Rect2(i * 8, i * 8, 1440 - i * 16, 900 - i * 16), Color(0.015, 0.03, 0.045, 0.035), false, 16)

func draw_hero(pos: Vector2, frame: int, left: bool, color: Color = Color.WHITE, lean: float = 0) -> void:
	var cell = heroes.get_size() / Vector2(4, 4)
	g.draw_set_transform(g.camera_offset + pos.snapped(Vector2(3, 3)), lean, Vector2(-1 if left else 1, 1))
	g.draw_texture_rect_region(heroes, Rect2(-48, -86, 96, 96), Rect2(Vector2(frame, g.hero_id) * cell + Vector2(2, 2), cell - Vector2(4, 4)), color)
	g.draw_set_transform(g.camera_offset)
