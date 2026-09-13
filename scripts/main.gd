extends Node2D

const Data = preload("res://scripts/game_data.gd")
const GOLD = Color("e7bc75")
const INK = Color("0c141c")
var rng = RandomNumberGenerator.new()
var font: Font = SystemFont.new()
var ui: CanvasLayer
var screen: Control
var hud: Label
var detail: Label
var notice: Label
var hero_id = 0
var drop_index = 1
var difficulty = 1
var mode = "menu"
var paused = false
var player = Vector2.ZERO
var aim = Vector2.RIGHT
var rooms: Array[Rect2] = []
var corridors: Array[Rect2] = []
var enemies: Array[Dictionary] = []
var loot: Array[Dictionary] = []
var fx: RefCounted
var combat: RefCounted
var art: RefCounted
var enemy_serial = 0
var effects: Array[Dictionary] = []
var inventory: Dictionary = {}
var bonuses: Dictionary = {}
var stage = 0
var wave = 0
var kills = 0
var elapsed = 0.0
var hp = 100.0
var attack_timer = 0.0
var dash_timer = 0.0
var dash_cooldown = 0.0
var invulnerable = 0.0
var transition_timer = 0.0
var toast_timer = 0.0
var revive_charges = 0
var boss_spawned = false
var portal = false
var portal_pos = Vector2.ZERO
var camera_offset = Vector2.ZERO
var inventory_open = false

func _ready() -> void:
	rng.randomize()
	fx = preload("res://scripts/pixel_fx.gd").new(self)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	combat = preload("res://scripts/melee_combat.gd").new(self)
	art = preload("res://scripts/world_art.gd").new(self)
	var keyed = ShaderMaterial.new()
	keyed.shader = load("res://assets/art/chroma_key.gdshader")
	material = keyed
	font.font_names = PackedStringArray(["PingFang SC", "Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
	var pixel_layer = CanvasLayer.new()
	pixel_layer.layer = 0
	add_child(pixel_layer)
	var pixel_cover = ColorRect.new()
	pixel_cover.size = Vector2(1440, 900)
	pixel_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pixel_material = ShaderMaterial.new()
	pixel_material.shader = load("res://assets/art/pixel_screen.gdshader")
	pixel_cover.material = pixel_material
	pixel_layer.add_child(pixel_cover)
	ui = CanvasLayer.new()
	add_child(ui)
	show_menu()

func fresh_screen() -> void:
	if is_instance_valid(screen):
		screen.queue_free()
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_theme_font_override("font", font)
	ui.add_child(screen)

func label_at(text: String, pos: Vector2, size: int, color: Color = Color("e8e7df")) -> Label:
	var node = Label.new()
	node.text = text
	node.position = pos
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	screen.add_child(node)
	return node

func panel(rect: Rect2, color: Color) -> Panel:
	var node = Panel.new()
	node.position = rect.position
	node.size = rect.size
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("33464e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	node.add_theme_stylebox_override("panel", style)
	screen.add_child(node)
	return node

func button_at(text: String, rect: Rect2, callback: Callable, selected: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", 20)
	node.add_theme_color_override("font_color", GOLD if selected else Color("d0dbda"))
	for state in ["normal", "hover", "pressed"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("30454a") if state == "hover" else Color("17262e")
		style.border_color = GOLD if selected else Color("3c5159")
		style.set_border_width_all(2 if selected else 1)
		style.set_corner_radius_all(0)
		node.add_theme_stylebox_override(state, style)
	node.pressed.connect(callback)
	screen.add_child(node)
	return node

func show_menu() -> void:
	art.load_stage(0)
	mode = "menu"
	fresh_screen()
	label_at("JOURNEY TO THE WEST   /   ROGUELIKE", Vector2(90, 60), 16, GOLD)
	label_at("西游冒险", Vector2(85, 98), 68)
	label_at("踏破六重天地，每一件宝物，都是新的可能。", Vector2(92, 193), 21, Color("93aaa9"))
	label_at("01  /  选择行者", Vector2(92, 270), 18, GOLD)
	for i in range(4):
		var x = 90 + i * 320
		panel(Rect2(x, 315, 300, 242), Color("111e28"))
		var portrait = Sprite2D.new()
		var cell = art.heroes.get_size() / Vector2(4, 4)
		portrait.texture = art.heroes
		portrait.region_enabled = true
		portrait.region_rect = Rect2(Vector2(0, i * cell.y), cell)
		portrait.material = material
		portrait.position = Vector2(x + 48, 359)
		portrait.scale = Vector2(64, 80) / cell
		screen.add_child(portrait)
		label_at(Data.HEROES[i].title, Vector2(x + 94, 348), 19, Data.HEROES[i].color)
		label_at(Data.HEROES[i].desc, Vector2(x + 24, 395), 16, Color("9fb0b6"))
		button_at(Data.HEROES[i].name + ("  ✓" if hero_id == i else "  →"), Rect2(x + 20, 483, 260, 52), func(): hero_id = i; show_menu(), hero_id == i)
	label_at("02  /  冒险规则", Vector2(92, 596), 18, GOLD)
	label_at("宝物掉落", Vector2(92, 645), 18)
	for i in range(3):
		button_at(["低 · 15%", "中 · 30%", "高 · 50%"][i], Rect2(205 + i * 136, 636, 124, 46), func(): drop_index = i; show_menu(), drop_index == i)
	label_at("妖怪难度", Vector2(695, 645), 18)
	for i in range(4):
		button_at(["简单", "普通", "困难", "地狱"][i], Rect2(807 + i * 126, 636, 114, 46), func(): difficulty = i; show_menu(), difficulty == i)
	button_at("启程西行     →", Rect2(1030, 760, 320, 68), start_run, true)
	label_at("WASD 移动   /   左键连击 · 右键重击   /   空格闪避", Vector2(92, 772), 17, Color("94a8ad"))
	label_at("无限叠层 · 属性封顶300% · 每3分钟难度提升", Vector2(92, 806), 15, Color("657f87"))
	queue_redraw()

func start_run() -> void:
	inventory.clear()
	bonuses = {"hp": 0.0, "damage": 0.0, "speed": 0.0, "rate": 0.0, "crit": 0.0, "regen": 0.0}
	stage = 0
	kills = 0
	elapsed = 0.0
	revive_charges = 0
	dash_cooldown = 0.0
	invulnerable = 0.0
	attack_timer = 0.0
	dash_timer = 0.0
	paused = false
	inventory_open = false
	hp = stat("hp")
	mode = "play"
	build_hud()
	generate_stage()

func stat(key: String) -> float:
	var base: Dictionary = Data.HEROES[hero_id]
	if key == "crit":
		return minf(3.0, base.crit + bonuses.crit)
	if key == "regen":
		return base.hp * minf(3.0, bonuses.regen)
	var bonus: float = bonuses.get(key, 0.0)
	if (hero_id == 2 and key == "rate") or (hero_id == 3 and key == "speed"):
		bonus *= 1.3
	return base[key] * minf(3.0, 1.0 + bonus)

func stacks(id: int) -> int:
	return inventory.get(id, 0)

func build_hud() -> void:
	fresh_screen()
	panel(Rect2(24, 22, 420, 107), Color("101e2bef"))
	hud = label_at("", Vector2(44, 34), 20)
	panel(Rect2(1000, 22, 416, 107), Color("101e2bef"))
	detail = label_at("", Vector2(1020, 36), 18)
	notice = label_at("", Vector2(470, 145), 23, GOLD)
	panel(Rect2(24, 828, 1392, 52), Color("101e2bef"))
	label_at("WASD 移动    左键 / J 连击    右键 / K 重击    空格 闪避    E 下一关    Tab 宝物    Esc 暂停", Vector2(44, 843), 17, Color("b4c6c8"))

func generate_stage() -> void:
	art.load_stage(stage)
	rooms.clear()
	corridors.clear()
	enemies.clear()
	loot.clear()
	combat.reset()
	fx.reset()
	effects.clear()
	wave = 0
	boss_spawned = false
	portal = false
	transition_timer = 1.8
	for y in range(2):
		for x in range(3):
			var origin = Vector2(x * 560, y * 510) + Vector2(rng.randf_range(-45, 45), rng.randf_range(-40, 40))
			rooms.append(Rect2(origin, Vector2(rng.randf_range(400, 460), rng.randf_range(350, 400))))
	for i in range(rooms.size() - 1):
		var a = rooms[i].get_center()
		var b = rooms[i + 1].get_center()
		corridors.append(Rect2(Vector2(minf(a.x, b.x) - 65, a.y - 65), Vector2(absf(b.x - a.x) + 130, 130)))
		corridors.append(Rect2(Vector2(b.x - 65, minf(a.y, b.y) - 65), Vector2(130, absf(b.y - a.y) + 130)))
	player = rooms[0].get_center()
	camera_offset = Vector2(720, 455) - player
	portal_pos = rooms[-1].get_center()
	refresh_hud()
	toast("第 %d 重天 · %s" % [stage + 1, Data.STAGES[stage][0]])

func walkable(pos: Vector2) -> bool:
	for rect in rooms:
		if rect.grow(-18).has_point(pos): return true
	for rect in corridors:
		if rect.grow(-18).has_point(pos): return true
	return false

func move_actor(pos: Vector2, velocity: Vector2) -> Vector2:
	var steps = maxi(1, ceili(velocity.length() / 8.0))
	var step = velocity / steps
	for i in range(steps):
		if walkable(pos + Vector2(step.x, 0)): pos.x += step.x
		if walkable(pos + Vector2(0, step.y)): pos.y += step.y
	return pos

func spawn_wave() -> void:
	wave += 1
	var boss = wave > (2 if stage == 5 else 3)
	boss_spawned = boss
	var count = 1 if boss else 5 + stage * 2 + difficulty * 2 + int(elapsed / 180.0) * 2 + wave
	for i in range(count):
		var room = rooms[rng.randi_range(0, rooms.size() - 1)]
		var pos = room.position + Vector2(rng.randf_range(45, room.size.x - 45), rng.randf_range(45, room.size.y - 45))
		if pos.distance_to(player) < 180: pos = rooms[-1].get_center()
		var factor: float = [0.7, 1.0, 1.4, 1.9][difficulty] * (1 + stage * 0.35)
		var health = (600.0 if boss else 42.0) * factor * (1 + int(elapsed / 180.0) * 0.2)
		enemy_serial += 1
		enemies.append({"id": enemy_serial, "knockback": Vector2.ZERO, "stun": 0.0, "windup": 0.0, "windup_max": 1.0, "target": pos, "attack_origin": pos, "pos": pos, "hp": health, "max_hp": health, "boss": boss, "damage": (22 if boss else 9) * factor * (1 + int(elapsed / 180.0) * 0.15), "speed": 74.0 + stage * 7 + (15 if boss else rng.randf_range(0, 25)), "hit": 0.0, "skill": 2.0, "burn": 0.0, "hidden": not boss and i % 5 == 4, "path": [], "path_timer": 0.0})
	toast(("妖王现身 · " + Data.STAGES[stage][2]) if boss else "第 %d 波 · 妖气涌动" % wave)

# Navigate via room/corridor centers, with a small visibility graph for reliable pursuit.
func visible_path(a: Vector2, b: Vector2) -> bool:
	var steps = maxi(1, int(a.distance_to(b) / 24))
	for i in range(steps + 1):
		if not walkable(a.lerp(b, float(i) / steps)): return false
	return true

func route(a: Vector2, b: Vector2) -> Array:
	if visible_path(a, b): return [b]
	var nodes: Array[Vector2] = [a, b]
	for r in rooms: nodes.append(r.get_center())
	for c in corridors:
		nodes.append(c.get_center())
		if c.size.x > c.size.y:
			nodes.append(Vector2(c.position.x + 65, c.get_center().y))
			nodes.append(Vector2(c.end.x - 65, c.get_center().y))
		else:
			nodes.append(Vector2(c.get_center().x, c.position.y + 65))
			nodes.append(Vector2(c.get_center().x, c.end.y - 65))
	var frontier: Array[int] = [0]
	var previous = {0: -1}
	while not frontier.is_empty():
		var current: int = frontier.pop_front()
		for j in range(1, nodes.size()):
			if not previous.has(j) and visible_path(nodes[current], nodes[j]):
				previous[j] = current
				if j == 1:
					var result: Array = [b]
					var p: int = current
					while p != 0:
						result.push_front(nodes[p])
						p = previous[p]
					return result
				frontier.append(j)
	return [a]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if mode == "chapter":
		if event.keycode == KEY_E: advance_stage()
		return
	if mode != "play": return
	if event.keycode == KEY_ESCAPE:
		paused = not paused
		inventory_open = false
		show_overlay() if paused else build_hud()
	elif event.keycode == KEY_TAB:
		inventory_open = not inventory_open
		paused = inventory_open
		show_overlay() if paused else build_hud()
	elif event.keycode == KEY_SPACE and not paused and dash_cooldown <= 0:
		var direction = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		combat.dodge(direction)
	elif event.keycode == KEY_E and portal and player.distance_to(portal_pos) < 90 and not paused:
		show_stage_clear()

func show_stage_clear() -> void:
	if mode != "play" or not portal or not enemies.is_empty(): return
	if stage == 5:
		finish(true)
		return
	mode = "chapter"
	combat.reset()
	fresh_screen()
	panel(Rect2(330, 175, 780, 530), Color("10212af5"))
	label_at("第 %d 关 / 已通过" % (stage + 1), Vector2(385, 215), 20, GOLD)
	label_at(Data.STAGES[stage][0] + " · 妖王已伏", Vector2(385, 265), 39)
	label_at("下一站", Vector2(385, 353), 18, Color("93aaa9"))
	label_at("第 %d 关 · %s" % [stage + 2, Data.STAGES[stage + 1][0]], Vector2(385, 387), 32, GOLD)
	label_at("""携带 %d 件宝物继续西行 · 角色与属性保留
本关场景结束，进入下一片天地。""" % total_items(), Vector2(385, 456), 20)
	button_at("进入下一关  →  [E]", Rect2(385, 580, 670, 66), advance_stage, true)
	queue_redraw()

func advance_stage() -> void:
	if mode != "chapter" or stage >= 5: return
	stage += 1
	mode = "play"
	paused = false
	inventory_open = false
	attack_timer = 0
	dash_timer = 0
	build_hud()
	generate_stage()

func show_overlay() -> void:
	fresh_screen()
	panel(Rect2(170, 85, 1100, 715), Color("10212afa"))
	label_at("行囊 · 宝物" if inventory_open else "暂停 · 稍作歇息", Vector2(210, 110), 34, GOLD)
	var stats_text = "攻击 %.0f    攻速 %.2f/s    移速 %.0f    暴击 %.0f%%    回复 %.1f/s" % [stat("damage"), stat("rate"), stat("speed"), stat("crit") * 100, stat("regen")]
	label_at(stats_text, Vector2(210, 165), 18)
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(210, 220)
	scroll.size = Vector2(1010, 430)
	screen.add_child(scroll)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	if inventory.is_empty():
		var empty = Label.new()
		empty.text = "行囊尚空。击败妖怪，拾取它们掉落的宝物。"
		box.add_child(empty)
	for id in inventory:
		var line = Label.new()
		line.text = "%s  ×%d     %s" % [Data.ITEMS[id][0], inventory[id], Data.ITEMS[id][3]]
		line.add_theme_color_override("font_color", Data.RARITY_COLORS[Data.ITEMS[id][1]])
		line.add_theme_font_size_override("font_size", 19)
		box.add_child(line)
	button_at("继续西行", Rect2(210, 698, 250, 58), func(): paused = false; inventory_open = false; build_hud(), true)
	button_at("返回启程界面", Rect2(950, 698, 270, 58), show_menu)

func _process(delta: float) -> void:
	if mode != "play" or paused:
		queue_redraw()
		return
	fx.tick(delta)
	if combat.presentation_tick(delta):
		camera_offset = Vector2(720, 455) - player + combat.camera_shake()
		queue_redraw()
		return
	var old_tier = int(elapsed / 180.0)
	elapsed += delta
	if int(elapsed / 180.0) > old_tier:
		advance_difficulty(old_tier, int(elapsed / 180.0))
	attack_timer -= delta
	dash_timer -= delta
	dash_cooldown -= delta
	invulnerable -= delta
	toast_timer -= delta
	if toast_timer <= 0: notice.text = ""
	hp = minf(stat("hp"), hp + stat("regen") * delta)
	var direction = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
	var previous_position = player
	combat.moving = direction.length_squared() > 0.1
	if combat.moving: combat.walk_clock += delta * 14
	if dash_timer > 0:
		player = move_actor(player, combat.dash_direction * stat("speed") * delta * 3.6)
	else:
		player = move_actor(player, direction * stat("speed") * delta * (0.65 if not combat.swing.is_empty() else 1.0))
	fx.motion(previous_position, player)
	camera_offset = Vector2(720, 455) - player + combat.camera_shake()
	aim = (get_global_mouse_position() - camera_offset - player).normalized()
	if aim.length_squared() < 0.1: aim = Vector2.RIGHT
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_physical_key_pressed(KEY_K):
		combat.begin_attack(true)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_physical_key_pressed(KEY_J):
		combat.begin_attack(false)
	combat.update(delta)
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].hp <= 0:
			kill_enemy(enemies[i])
			enemies.remove_at(i)
	for i in range(loot.size() - 1, -1, -1):
		var distance: float = loot[i].pos.distance_to(player)
		if distance < 110: loot[i].pos = loot[i].pos.move_toward(player, delta * 270)
		if distance < 27:
			collect(loot[i].id)
			loot.remove_at(i)
	for effect in effects:
		effect.life -= delta
		if effect.get("hazard", false) and effect.life < 0.3 and not effect.triggered:
			effect.triggered = true
			if effect.pos.distance_to(player) < 65: hurt(20.0 * (1 + stage * 0.3))
	effects = effects.filter(func(e): return e.life > 0)
	if enemies.is_empty() and not portal:
		transition_timer -= delta
		if transition_timer <= 0:
			if boss_spawned:
				portal = true
				toast("妖王已伏 · 前往金色法阵，按 E 继续")
			else:
				spawn_wave()
				transition_timer = 2.5
	if hp <= 0:
		if revive_charges > 0:
			revive_charges -= 1
			hp = stat("hp")
			invulnerable = 3.0
			toast("九转还魂 · 重获新生")
		else:
			finish(false)
			return
	refresh_hud()
	queue_redraw()

func refresh_hud() -> void:
	hud.text = "%s   /   %s\n生命  %d / %d     宝物 %d 件" % [Data.HEROES[hero_id].name, Data.STAGES[stage][0], ceili(hp), int(stat("hp")), total_items()]
	detail.text = "%02d:%02d   难度 %d · %s\n%s   剩余妖怪 %d   闪避 %s" % [int(elapsed) / 60, int(elapsed) % 60, 1 + int(elapsed / 180), ["简单", "普通", "困难", "地狱"][difficulty], "妖王战" if boss_spawned else "波次 %d / %d" % [wave, 2 if stage == 5 else 3], enemies.size(), "就绪" if dash_cooldown <= 0 else "%.1fs" % dash_cooldown]


func advance_difficulty(old_tier: int, new_tier: int) -> void:
	var health_ratio = (1.0 + new_tier * 0.2) / (1.0 + old_tier * 0.2)
	var attack_ratio = (1.0 + new_tier * 0.15) / (1.0 + old_tier * 0.15)
	for enemy in enemies:
		enemy.hp *= health_ratio
		enemy.max_hp *= health_ratio
		enemy.damage *= attack_ratio
	toast("劫数加深 · 难度 %d · 妖怪生命与攻击提升" % (new_tier + 1))

func hit_enemy(enemy: Dictionary, damage: float) -> void:
	var crit = stat("crit")
	var level = int(crit) + (1 if rng.randf() < fmod(crit, 1.0) else 0)
	damage *= 1.0 + level * (1.5 if hero_id == 0 else 1.0)
	enemy.hp -= damage
	enemy.hit = 0.14
	effects.append({"pos": enemy.pos + Vector2(-12, -28), "life": 0.65, "max": 0.65, "text": str(int(damage)) + ("!" if level > 0 else ""), "color": GOLD if level > 0 else Color.WHITE})
	if stacks(9) > 0:
		for other in enemies:
			if other != enemy and other.pos.distance_to(enemy.pos) < 100:
				other.hp -= damage * minf(3.0, stacks(9) * 0.2)
	if rng.randf() < minf(1, stacks(10) * 0.15): enemy.pos = move_actor(enemy.pos, player.direction_to(enemy.pos) * 65)
	if stacks(13) > 0: enemy.burn = 2.0

func hurt(damage: float) -> void:
	if invulnerable > 0: return
	if hero_id == 3 and rng.randf() < 0.1:
		invulnerable = 0.3
		return
	hp -= damage * (1.0 - minf(0.8, stacks(16) * 0.2))
	invulnerable = 0.65
	combat.shake = 6
	combat.play("hurt")
	combat.burst(player, Color("ef8a77"), 7)
	effects.append({"pos": player + Vector2(0, -40), "life": 0.6, "max": 0.6, "text": "受击", "color": Color("fa8878")})

func kill_enemy(enemy: Dictionary) -> void:
	kills += 1
	combat.burst(enemy.pos, Color("b9e4d4"), 12)
	hp = minf(stat("hp"), hp + Data.HEROES[hero_id].hp * minf(3.0, stacks(11) * 0.02))
	if rng.randf() < [0.15, 0.30, 0.50][drop_index]:
		var roll = rng.randf()
		var rarity = 0 if roll < 0.66 else (1 if roll < 0.89 else (2 if roll < 0.98 else 3))
		var choices: Array[int] = []
		for i in range(Data.ITEMS.size()):
			if Data.ITEMS[i][1] == rarity: choices.append(i)
		loot.append({"pos": enemy.pos, "id": choices[rng.randi_range(0, choices.size() - 1)]})

func collect(id: int, copied: bool = false) -> void:
	var old_max = stat("hp")
	inventory[id] = stacks(id) + 1
	for key in Data.ITEMS[id][2]: bonuses[key] += Data.ITEMS[id][2][key]
	if hero_id == 1: bonuses.hp += 0.02
	if id == 14: revive_charges += 1
	hp += stat("hp") - old_max
	if id == 17:
		var options = inventory.keys().filter(func(key): return key != 17)
		if not options.is_empty(): collect(options[rng.randi_range(0, options.size() - 1)], true)
	toast(("变化复制 · " if copied else "获得 · ") + Data.ITEMS[id][0] + "  ×" + str(stacks(id)))

func total_items() -> int:
	var total = 0
	for count in inventory.values(): total += count
	return total

func toast(text: String) -> void:
	if is_instance_valid(notice): notice.text = text
	toast_timer = 3.2

func finish(won: bool) -> void:
	mode = "end"
	fresh_screen()
	panel(Rect2(380, 200, 680, 460), Color("10212af5"))
	label_at("功成 · 问道西天" if won else "此劫未渡", Vector2(440, 255), 48, GOLD)
	label_at("%s走过了 %d 重天地\n历时 %02d:%02d · 降伏 %d 只妖怪\n累计宝物 %d 件 · 下一次，再续传奇。" % [Data.HEROES[hero_id].name, mini(stage + 1, 6), int(elapsed) / 60, int(elapsed) % 60, kills, total_items()], Vector2(440, 355), 24)
	button_at("再次启程  →", Rect2(440, 540, 550, 65), show_menu, true)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1440, 900), INK)
	if mode == "menu":
		art.menu_background()
		for i in range(7):
			draw_arc(Vector2(1200, 135), 80 + i * 32, 0, TAU, 100, Color(0.6, 0.65, 0.5, 0.055), 1)
		return
	art.environment()
	var tint: Color = Data.STAGES[mini(stage, 5)][3]
	combat.draw_warnings()
	if portal:
		draw_arc(portal_pos, 55 + sin(elapsed * 3) * 4, 0, TAU, 64, GOLD, 3)
		draw_arc(portal_pos, 42, -elapsed, TAU - elapsed - 0.5, 48, GOLD, 2)
		draw_string(font, portal_pos + Vector2(-52, -70), "E · " + ("完成取经" if stage == 5 else "踏入下一关"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, GOLD)
	for item in loot:
		var color: Color = Data.RARITY_COLORS[Data.ITEMS[item.id][1]]
		draw_circle(item.pos, 19, Color(color, 0.12))
		draw_colored_polygon(PackedVector2Array([item.pos + Vector2(0, -11), item.pos + Vector2(9, 0), item.pos + Vector2(0, 11), item.pos + Vector2(-9, 0)]), color)
		if item.pos.distance_to(player) < 130: draw_string(font, item.pos + Vector2(-32, -25), Data.ITEMS[item.id][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color)
	fx.draw_ground()
	art.characters()
	combat.draw_swing()
	combat.draw_particles()
	fx.draw_hits()
	for effect in effects:
		if effect.has("ring"):
			draw_arc(effect.pos, effect.ring * (1.2 - effect.life / effect.max * 0.2), 0, TAU, 48, Color(effect.color, effect.life / effect.max), 5)
		elif effect.get("hazard", false):
			draw_circle(effect.pos, 65, Color(effect.color, 0.15 if effect.life > 0.3 else 0.5))
			draw_arc(effect.pos, 65, 0, TAU, 40, effect.color, 2)
		else: draw_string(font, effect.pos + Vector2(0, -28 * (1 - effect.life / effect.max)), effect.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, effect.color)
	art.atmosphere()
	if combat.flash > 0: draw_rect(Rect2(0, 0, 1440, 900), Color(1, 0.83, 0.5, combat.flash))
	if not combat.swing.is_empty():
		draw_string(font, Vector2(600, 785), "重击 · 破阵" if combat.swing.heavy else ["", "一式 · 起棍", "二式 · 横扫", "三式 · 震岳"][combat.combo], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)
	draw_string(font, Vector2(44, 790), "重击  " + ("就绪" if combat.heavy_cooldown <= 0 else "%.1fs" % combat.heavy_cooldown), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, GOLD)
	# Compact map, showing all rooms and current enemies; hidden enemies need true sight.
	draw_rect(Rect2(1210, 670, 206, 140), Color("0a121cdd"))
	for r in rooms: draw_rect(Rect2(Vector2(1220, 681) + r.position * 0.11, r.size * 0.11), tint)
	for c in corridors: draw_rect(Rect2(Vector2(1220, 681) + c.position * 0.11, c.size * 0.11), tint.darkened(0.3))
	for enemy in enemies:
		if not enemy.hidden or stacks(12) > 0: draw_circle(Vector2(1220, 681) + enemy.pos * 0.11, 2, Color("ed8c7f"))
	if portal: draw_circle(Vector2(1220, 681) + portal_pos * 0.11, 4, GOLD)
	draw_circle(Vector2(1220, 681) + player * 0.11, 4, Color.WHITE)

func room_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.67)
	style.border_color = color.darkened(0.16)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	return style

func _exit_tree() -> void:
	if combat != null:
		combat.reset()
		for voice in combat.voices: voice.stream = null
		combat.sfx.clear()
