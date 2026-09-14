extends Node2D

const Data = preload("res://scripts/game_data.gd")
const GOLD = Color("c69a3e")
const INK = Color("0a080c")
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
var hades: Node3D
var pixel_cover: ColorRect

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
	# Fullscreen + screen-texture postprocess crashes GL Compatibility on some NVIDIA drivers.
	pixel_cover = null
	ui = CanvasLayer.new()
	add_child(ui)
	hades = preload("res://scripts/hades_world.gd").new()
	hades.setup(self)
	add_child(hades)
	show_menu()

func _notification(what: int) -> void:
	# If the OS/driver already jumped into exclusive fullscreen, drop to borderless.
	if what == NOTIFICATION_WM_SIZE_CHANGED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _shortcut_input(event: InputEvent) -> void:
	if _is_fullscreen_toggle(event):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()

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
	label_at("CRIMSON COVENANT   /   HUNTER ROGUELIKE", Vector2(90, 60), 16, GOLD)
	label_at("血契", Vector2(85, 98), 68)
	label_at("猎人必须狩猎。六处猎场，每一件遗物，都是新的血契。", Vector2(92, 193), 21, Color("8a7a66"))
	label_at("01  /  选择猎人", Vector2(92, 270), 18, GOLD)
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
	label_at("02  /  狩猎规则", Vector2(92, 596), 18, GOLD)
	label_at("遗物掉落", Vector2(92, 645), 18)
	for i in range(3):
		button_at(["低 · 15%", "中 · 30%", "高 · 50%"][i], Rect2(205 + i * 136, 636, 124, 46), func(): drop_index = i; show_menu(), drop_index == i)
	label_at("猎物难度", Vector2(695, 645), 18)
	for i in range(4):
		button_at(["浅猎", "夜巡", "血月", "噩梦"][i], Rect2(807 + i * 126, 636, 114, 46), func(): difficulty = i; show_menu(), difficulty == i)
	button_at("开始狩猎     →", Rect2(1030, 760, 320, 68), start_run, true)
	label_at("WASD 移动   /   左键连击 · 右键重击   /   空格侧步", Vector2(92, 772), 17, Color("8a7a66"))
	label_at("无限叠层 · 属性封顶300% · 每3分钟猎场加深", Vector2(92, 806), 15, Color("5a4a42"))
	if hades:
		hades.set_active(false)
	if pixel_cover:
		pixel_cover.visible = true
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
	if pixel_cover:
		pixel_cover.visible = false
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
	label_at("WASD 移动    左键 / J 连击    右键 / K 重击    空格 侧步    E 下一猎场    Tab 遗物    Esc 暂停", Vector2(44, 843), 17, Color("b4c6c8"))

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
	if hades:
		hades.rebuild()
	refresh_hud()
	toast("第 %d 夜 · %s" % [stage + 1, Data.STAGES[stage][0]])

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
	toast(("猎场之主 · " + Data.STAGES[stage][2]) if boss else "第 %d 波 · 兽潮将至" % wave)

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

func _toggle_fullscreen() -> void:
	# Borderless fullscreen. Exclusive mode (Alt+Enter default) hard-crashes
	# OpenGL Compatibility on several NVIDIA laptops when the swap chain resizes.
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _is_fullscreen_toggle(event: InputEvent) -> bool:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return false
	return event.keycode == KEY_F11 or (event.alt_pressed and event.keycode == KEY_ENTER)

func _input(event: InputEvent) -> void:
	if _is_fullscreen_toggle(event):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if _is_fullscreen_toggle(event):
		_toggle_fullscreen()
		return
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
	label_at("第 %d 夜 / 已猎过" % (stage + 1), Vector2(385, 215), 20, GOLD)
	label_at(Data.STAGES[stage][0] + " · 猎物已伏", Vector2(385, 265), 39)
	label_at("下一猎场", Vector2(385, 353), 18, Color("8a7a66"))
	label_at("第 %d 夜 · %s" % [stage + 2, Data.STAGES[stage + 1][0]], Vector2(385, 387), 32, GOLD)
	label_at("""携带 %d 件遗物继续狩猎 · 猎人与属性保留
本夜结束，踏入下一片雾街。""" % total_items(), Vector2(385, 456), 20)
	button_at("进入下一猎场  →  [E]", Rect2(385, 580, 670, 66), advance_stage, true)
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
	label_at("行囊 · 遗物" if inventory_open else "暂停 · 灯火暂歇", Vector2(210, 110), 34, GOLD)
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
		empty.text = "行囊尚空。击败猎物，拾取它们掉落的遗物。"
		box.add_child(empty)
	for id in inventory:
		var line = Label.new()
		line.text = "%s  ×%d     %s" % [Data.ITEMS[id][0], inventory[id], Data.ITEMS[id][3]]
		line.add_theme_color_override("font_color", Data.RARITY_COLORS[Data.ITEMS[id][1]])
		line.add_theme_font_size_override("font_size", 19)
		box.add_child(line)
	button_at("继续狩猎", Rect2(210, 698, 250, 58), func(): paused = false; inventory_open = false; build_hud(), true)
	button_at("返回猎人选择", Rect2(950, 698, 270, 58), show_menu)

func _process(delta: float) -> void:
	if mode != "play" or paused:
		if hades:
			hades.set_active(mode == "play")
			if mode == "play":
				hades.sync()
		queue_redraw()
		return
	fx.tick(delta)
	if combat.presentation_tick(delta):
		camera_offset = Vector2(720, 455) - player + combat.camera_shake()
		if hades:
			hades.sync()
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
	if hades and hades.camera and hades.camera.current:
		aim = (hades.pick_ground() - player)
	else:
		aim = (get_global_mouse_position() - camera_offset - player)
	aim = aim.normalized() if aim.length_squared() > 0.1 else Vector2.RIGHT
	if hades:
		hades.sync()
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
				toast("猎物已伏 · 前往血色法阵，按 E 继续")
			else:
				spawn_wave()
				transition_timer = 2.5
	if hp <= 0:
		if revive_charges > 0:
			revive_charges -= 1
			hp = stat("hp")
			invulnerable = 3.0
			toast("还魂血丹 · 猎人再起")
		else:
			finish(false)
			return
	refresh_hud()
	queue_redraw()

func refresh_hud() -> void:
	hud.text = "%s   /   %s\n生命  %d / %d     遗物 %d 件" % [Data.HEROES[hero_id].name, Data.STAGES[stage][0], ceili(hp), int(stat("hp")), total_items()]
	detail.text = "%02d:%02d   难度 %d · %s\n%s   剩余猎物 %d   侧步 %s" % [int(elapsed) / 60, int(elapsed) % 60, 1 + int(elapsed / 180), ["浅猎", "夜巡", "血月", "噩梦"][difficulty], "猎主战" if boss_spawned else "波次 %d / %d" % [wave, 2 if stage == 5 else 3], enemies.size(), "就绪" if dash_cooldown <= 0 else "%.1fs" % dash_cooldown]


func advance_difficulty(old_tier: int, new_tier: int) -> void:
	var health_ratio = (1.0 + new_tier * 0.2) / (1.0 + old_tier * 0.2)
	var attack_ratio = (1.0 + new_tier * 0.15) / (1.0 + old_tier * 0.15)
	for enemy in enemies:
		enemy.hp *= health_ratio
		enemy.max_hp *= health_ratio
		enemy.damage *= attack_ratio
	toast("血月加深 · 难度 %d · 猎物生命与攻击提升" % (new_tier + 1))

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
	toast(("血契摹写 · " if copied else "获得 · ") + Data.ITEMS[id][0] + "  ×" + str(stacks(id)))

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
	label_at("夜尽 · 契约仍在" if won else "猎人倒下了", Vector2(440, 255), 48, GOLD)
	label_at("%s走过了 %d 处猎场\n历时 %02d:%02d · 猎杀 %d 头猎物\n累计遗物 %d 件 · 再猎一次。" % [Data.HEROES[hero_id].name, mini(stage + 1, 6), int(elapsed) / 60, int(elapsed) % 60, kills, total_items()], Vector2(440, 355), 24)
	button_at("再次狩猎  →", Rect2(440, 540, 550, 65), show_menu, true)
	queue_redraw()

func _draw() -> void:
	if mode == "menu" or mode == "end" or mode == "chapter":
		draw_rect(Rect2(0, 0, 1440, 900), INK)
		if mode == "menu":
			art.menu_background()
			for i in range(7):
				draw_arc(Vector2(1200, 135), 80 + i * 32, 0, TAU, 100, Color(0.6, 0.65, 0.5, 0.055), 1)
		return
	# Play mode: 3D world is the scene. Only screen-space HUD stays on the 2D canvas.
	var tint: Color = Data.STAGES[mini(stage, 5)][3]
	if combat.flash > 0:
		draw_rect(Rect2(0, 0, 1440, 900), Color(1, 0.83, 0.5, combat.flash))
	if not combat.swing.is_empty():
		draw_string(font, Vector2(600, 785), "重击 · 开刃" if combat.swing.heavy else ["", "一式 · 短锯", "二式 · 回转", "三式 · 开刃"][combat.combo], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)
	draw_string(font, Vector2(44, 790), "重击  " + ("就绪" if combat.heavy_cooldown <= 0 else "%.1fs" % combat.heavy_cooldown), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, GOLD)
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
