extends Node3D
## Hades-style presentation: 3D chambers, 2D sprites, locked 3/4 camera.
## Gameplay stays on the 2D plane; (x, y) maps to (x, 0, z).

const UNIT := 0.024
const PLATFORM_H := 0.72
const PILLAR_H := 3.4

var g: Node2D
var camera: Camera3D
var key_light: DirectionalLight3D
var fill_light: DirectionalLight3D
var world_env: WorldEnvironment
var rooms_node: Node3D
var actors_node: Node3D
var markers_node: Node3D
var player_sprite: Sprite3D
var weapon: MeshInstance3D
var portal_mesh: MeshInstance3D
var enemy_sprites: Dictionary = {}
var loot_meshes: Dictionary = {}
var warn_meshes: Array[MeshInstance3D] = []
var floor_mat: StandardMaterial3D
var side_mat: StandardMaterial3D
var wall_mat: StandardMaterial3D
var pillar_mat: StandardMaterial3D
var gold_mat: StandardMaterial3D
var heroes: Texture2D
var minions: Dictionary = {}
var built_stage := -1
var built_seed := -1

func setup(game: Node2D) -> void:
	g = game
	heroes = load("res://assets/art/heroes_pixel_walk.png")
	for animation in ["idle", "walk", "attack"]:
		minions[animation] = load("res://assets/spritecook/%s_sheet.png" % animation)
	_make_environment()
	_make_camera()
	_make_lights()
	rooms_node = Node3D.new()
	rooms_node.name = "Chambers"
	add_child(rooms_node)
	actors_node = Node3D.new()
	actors_node.name = "Actors"
	add_child(actors_node)
	markers_node = Node3D.new()
	markers_node.name = "Markers"
	add_child(markers_node)
	player_sprite = _make_sprite(96)
	actors_node.add_child(player_sprite)
	weapon = _make_weapon()
	actors_node.add_child(weapon)
	portal_mesh = _make_portal()
	markers_node.add_child(portal_mesh)

func to3(p: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(p.x * UNIT, y, p.y * UNIT)

func pick_ground() -> Vector2:
	if camera == null or not camera.current or not is_inside_tree():
		return g.player + g.aim
	var vp := get_viewport()
	if vp == null:
		return g.player + g.aim
	var size := vp.get_visible_rect().size
	if size.x < 8.0 or size.y < 8.0:
		return g.player + g.aim
	var mouse := vp.get_mouse_position()
	if not mouse.is_finite():
		return g.player
	var origin := camera.project_ray_origin(mouse)
	var dir := camera.project_ray_normal(mouse)
	if not origin.is_finite() or not dir.is_finite() or absf(dir.y) < 0.0001:
		return g.player
	var hit := origin + dir * (-origin.y / dir.y)
	if not hit.is_finite():
		return g.player
	return Vector2(hit.x, hit.z) / UNIT

func set_active(on: bool) -> void:
	if camera:
		camera.current = on
	visible = on

func rebuild() -> void:
	for child in rooms_node.get_children():
		child.queue_free()
	_stage_palette()
	for room in g.rooms:
		_add_platform(room, true)
	for hall in g.corridors:
		_add_platform(hall, false)
	built_stage = g.stage
	if g.player != Vector2.ZERO or not g.rooms.is_empty():
		var focus := to3(g.player)
		camera.global_position = focus + Vector3(0, 12.4, 10.6)
		camera.look_at(focus + Vector3(0, 0.4, 0), Vector3.UP)
		set_active(g.mode == "play")

func sync() -> void:
	if g.mode != "play":
		set_active(false)
		return
	set_active(true)
	if built_stage != g.stage or rooms_node.get_child_count() == 0:
		rebuild()
	_follow_camera()
	_sync_player()
	_sync_enemies()
	_sync_loot()
	_sync_portal()
	_sync_warnings()
	_sync_weapon()

func _make_environment() -> void:
	world_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.018, 0.028, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.38, 0.46)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color(0.07, 0.1, 0.14)
	env.fog_density = 0.018
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)

func _make_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 17.5
	camera.near = 0.05
	camera.far = 120.0
	camera.current = false
	add_child(camera)

func _make_lights() -> void:
	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-52, 38, 0)
	key_light.light_energy = 1.15
	key_light.shadow_enabled = false
	add_child(key_light)
	fill_light = DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-20, -130, 0)
	fill_light.light_color = Color(0.45, 0.62, 0.78)
	fill_light.light_energy = 0.28
	add_child(fill_light)
	var bounce := OmniLight3D.new()
	bounce.name = "Bounce"
	bounce.light_energy = 0.9
	bounce.omni_range = 28.0
	bounce.shadow_enabled = false
	add_child(bounce)

func _stage_palette() -> void:
	var tint: Color = g.Data.STAGES[g.stage][3]
	key_light.light_color = tint.lerp(Color(1.0, 0.92, 0.78), 0.55)
	fill_light.light_color = tint.lerp(Color(0.4, 0.55, 0.7), 0.4)
	if world_env.environment:
		world_env.environment.background_color = tint.darkened(0.86)
		world_env.environment.fog_light_color = tint.darkened(0.72)
	floor_mat = _tex_mat(g.art.biomes, tint.lightened(0.08), 0.82)
	side_mat = _color_mat(tint.darkened(0.55), 0.9)
	wall_mat = _color_mat(tint.darkened(0.35), 0.78)
	pillar_mat = _color_mat(tint.lerp(Color("c9b07a"), 0.25).darkened(0.15), 0.7)
	gold_mat = _color_mat(Color("e7bc75"), 0.35)
	gold_mat.emission_enabled = true
	gold_mat.emission = Color("e7bc75")
	gold_mat.emission_energy_multiplier = 0.55

func _tex_mat(tex: Texture2D, color: Color, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = color
	mat.roughness = rough
	mat.uv1_scale = Vector3(2.2, 2.2, 2.2)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return mat

func _color_mat(color: Color, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	return mat

func _add_platform(rect: Rect2, chamber: bool) -> void:
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	var height := PLATFORM_H if chamber else PLATFORM_H * 0.72
	box.size = Vector3(rect.size.x * UNIT, height, rect.size.y * UNIT)
	body.mesh = box
	body.position = to3(rect.get_center(), -height * 0.5)
	body.material_override = side_mat
	# Top slab so the walkable face keeps the biome texture.
	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(rect.size.x * UNIT - 0.04, 0.04, rect.size.y * UNIT - 0.04)
	top.mesh = top_mesh
	top.material_override = floor_mat
	top.position = Vector3(0, height * 0.5 + 0.01, 0)
	body.add_child(top)
	rooms_node.add_child(body)
	if chamber:
		for corner in [Vector2(18, 18), Vector2(rect.size.x - 18, 18), Vector2(18, rect.size.y - 18), rect.size - Vector2(18, 18)]:
			_add_pillar(rect.position + corner)
		_add_rim(rect)

func _add_pillar(pos: Vector2) -> void:
	var pillar := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.42, PILLAR_H, 0.42)
	pillar.mesh = mesh
	pillar.material_override = pillar_mat
	pillar.position = to3(pos, PILLAR_H * 0.5)
	rooms_node.add_child(pillar)

func _add_rim(rect: Rect2) -> void:
	var thickness := 0.16
	var height := 0.38
	var w := rect.size.x * UNIT
	var d := rect.size.y * UNIT
	var center := to3(rect.get_center(), height * 0.5)
	var edges := [
		[Vector3(0, 0, -d * 0.5 + thickness * 0.5), Vector3(w, height, thickness)],
		[Vector3(0, 0, d * 0.5 - thickness * 0.5), Vector3(w, height, thickness)],
		[Vector3(-w * 0.5 + thickness * 0.5, 0, 0), Vector3(thickness, height, d)],
		[Vector3(w * 0.5 - thickness * 0.5, 0, 0), Vector3(thickness, height, d)]
	]
	for edge in edges:
		var rail := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = edge[1]
		rail.mesh = mesh
		rail.material_override = wall_mat
		rail.position = center + edge[0]
		rooms_node.add_child(rail)

func _make_sprite(pixel_h: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.pixel_size = UNIT * 0.92
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.35
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = true
	sprite.double_sided = true
	sprite.position.y = pixel_h * sprite.pixel_size * 0.42
	sprite.region_enabled = true
	return sprite

func _make_weapon() -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.07, 0.07, 2.15)
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("e8bb65")
	mat.metallic = 0.55
	mat.roughness = 0.38
	node.material_override = mat
	return node

func _make_portal() -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.15
	mesh.bottom_radius = 1.15
	mesh.height = 0.08
	mesh.rings = 1
	node.mesh = mesh
	node.visible = false
	return node

func _follow_camera() -> void:
	var focus := to3(g.player, 0.0)
	var shake := Vector3(g.combat.camera_shake().x, 0, g.combat.camera_shake().y) * UNIT
	var goal := focus + Vector3(0, 12.4, 10.6) + shake
	if not goal.is_finite():
		return
	if camera.global_position.is_finite():
		camera.global_position = camera.global_position.lerp(goal, 0.22)
	else:
		camera.global_position = goal
	var look := focus + Vector3(0, 0.4, 0)
	if camera.global_position.distance_squared_to(look) > 0.04:
		camera.look_at(look, Vector3.UP)
	var bounce := get_node_or_null("Bounce") as OmniLight3D
	if bounce:
		bounce.global_position = focus + Vector3(0, 3.2, 0)

func _sync_player() -> void:
	player_sprite.position = to3(g.player, 0.02)
	player_sprite.texture = heroes
	var cell: Vector2 = heroes.get_size() / Vector2(4, 4)
	var frame := int(g.combat.walk_clock / 1.7) % 4 if g.combat.moving else 0
	player_sprite.region_rect = Rect2(Vector2(frame, g.hero_id) * cell + Vector2(2, 2), cell - Vector2(4, 4))
	player_sprite.flip_h = g.aim.x < 0
	player_sprite.modulate = Color(1.7, 1.7, 1.7) if g.invulnerable > 0 and int(g.elapsed * 14) % 2 == 0 else Color.WHITE
	var bob := sin(g.combat.walk_clock) * 0.05 if g.combat.moving else sin(g.elapsed * 2) * 0.02
	player_sprite.position.y += 0.85 + bob

func _sync_weapon() -> void:
	var aim: Vector2 = g.aim
	if not g.combat.swing.is_empty():
		aim = g.combat.swing.aim
	var angle: float = aim.angle()
	weapon.visible = true
	weapon.position = to3(g.player, 1.05)
	# 2D angle 0 = +X; weapon mesh extends along local -Z after this yaw.
	weapon.rotation = Vector3(0.55, -angle + PI * 0.5, 0)
	if not g.combat.swing.is_empty():
		var swing: Dictionary = g.combat.swing
		var p: float = clampf((swing.time - swing.windup) / maxf(0.001, swing.end - swing.windup), 0, 1)
		weapon.rotation.y = -angle + PI * 0.5 + lerp(-swing.angle, swing.angle, p)

func _sync_enemies() -> void:
	var live: Dictionary = {}
	for enemy in g.enemies:
		live[enemy.id] = true
		var sprite: Sprite3D = enemy_sprites.get(enemy.id)
		if sprite == null:
			sprite = _make_sprite(80 if not enemy.boss else 140)
			actors_node.add_child(sprite)
			enemy_sprites[enemy.id] = sprite
		sprite.position = to3(enemy.pos, 0.02)
		sprite.position.y += 0.7 if enemy.boss else 0.55
		sprite.flip_h = enemy.pos.x > g.player.x
		sprite.modulate = Color(2.2, 2.2, 2.2) if enemy.hit > 0 else Color.WHITE
		if enemy.boss:
			sprite.texture = g.art.actors
			var cell: Vector2 = sprite.texture.get_size() / Vector2(4, 2)
			var index: int = [7, 6, 5, 7, 6, 7][g.stage]
			sprite.region_rect = Rect2(Vector2(index % 4, int(index / 4)) * cell + Vector2(3, 3), cell - Vector2(6, 6))
			sprite.pixel_size = UNIT * 1.35
		else:
			var animation := "attack" if enemy.windup > 0 else ("walk" if enemy.pos.distance_to(g.player) > 43 and enemy.stun <= 0 else "idle")
			sprite.texture = minions[animation]
			var frame := int(g.elapsed * 10 + enemy.id) % 8
			if enemy.windup > 0:
				frame = mini(7, int((1.0 - enemy.windup / enemy.windup_max) * 8))
			sprite.region_rect = Rect2(frame * 80, 0, 80, 80)
		sprite.visible = not (enemy.hidden and enemy.pos.distance_to(g.player) > 145 + g.stacks(12) * 130)
	var stale: Array = []
	for id in enemy_sprites.keys():
		if not live.has(id):
			stale.append(id)
	for id in stale:
		enemy_sprites[id].queue_free()
		enemy_sprites.erase(id)

func _sync_loot() -> void:
	while loot_meshes.size() < g.loot.size():
		var node := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.22
		mesh.height = 0.44
		node.mesh = mesh
		markers_node.add_child(node)
		loot_meshes[loot_meshes.size()] = node
	for i in range(loot_meshes.size()):
		var node: MeshInstance3D = loot_meshes[i]
		if i >= g.loot.size():
			node.visible = false
			continue
		node.visible = true
		var color: Color = g.Data.RARITY_COLORS[g.Data.ITEMS[g.loot[i].id][1]]
		var mat := _color_mat(color, 0.25)
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.8
		node.material_override = mat
		node.position = to3(g.loot[i].pos, 0.45 + sin(g.elapsed * 4 + i) * 0.08)

func _sync_portal() -> void:
	portal_mesh.visible = g.portal
	if not g.portal:
		return
	portal_mesh.material_override = gold_mat
	portal_mesh.position = to3(g.portal_pos, 0.06)
	portal_mesh.rotate_y(0.03)

func _sync_warnings() -> void:
	for node in warn_meshes:
		node.queue_free()
	warn_meshes.clear()
	for enemy in g.enemies:
		if enemy.windup <= 0:
			continue
		var radius: float = (105.0 if enemy.boss else 42.0) * UNIT
		var disc := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = 0.04
		disc.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.18, 0.1, 0.22 + (1.0 - enemy.windup / enemy.windup_max) * 0.25)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		disc.material_override = mat
		disc.position = to3(enemy.target, 0.04)
		markers_node.add_child(disc)
		warn_meshes.append(disc)
