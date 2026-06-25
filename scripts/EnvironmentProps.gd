extends Node3D

const BASE = "res://assets/nature/kenney_nature_kit_glb_cc0_v1/kenney_nature_kit_glb_cc0_v1/models_glb/"

const ROCKS_LARGE  = ["rock_largeA.glb","rock_largeB.glb","rock_largeC.glb","rock_largeD.glb"]
const ROCKS_SMALL  = ["rock_smallA.glb","rock_smallB.glb","rock_smallC.glb","rock_smallD.glb"]
const ROCKS_TALL   = ["rock_tallA.glb","rock_tallB.glb","rock_tallC.glb"]
const BUSHES       = ["plant_bush.glb","plant_bushLarge.glb","plant_bushSmall.glb","plant_bushDetailed.glb"]
const FLOWERS      = ["flower_purpleA.glb","flower_redA.glb","flower_yellowA.glb",
					   "flower_purpleB.glb","flower_redB.glb","flower_yellowB.glb"]
const GRASS_LIST   = ["grass.glb","grass_large.glb","grass_leafs.glb"]
const MUSHROOMS    = ["mushroom_red.glb","mushroom_redGroup.glb","mushroom_tan.glb","mushroom_tanGroup.glb"]
const LOGS         = ["log.glb","log_large.glb","log_stack.glb","log_stackLarge.glb"]
const STUMPS       = ["stump_round.glb","stump_old.glb","stump_roundDetailed.glb"]
const FENCES       = ["fence_simple.glb","fence_planks.glb","fence_simpleHigh.glb"]

# Zone centers
const ZONES = [
	Vector3(-20, 0, -20), Vector3(20, 0, -20),
	Vector3(-20, 0, 20),  Vector3(20, 0, 20)
]

func _ready():
	call_deferred("_spawn_all")

func _spawn_all():
	_scatter_zone_rocks()
	_scatter_bushes_and_flowers()
	_scatter_mushrooms()
	_scatter_grass()
	_place_log_stacks()
	_place_camp_fences()
	_scatter_stumps()

func _place(path: String, pos: Vector3, rot_y: float = 0.0, scale_mult: float = 1.0):
	var packed = load(BASE + path)
	if not packed:
		return
	var node = packed.instantiate()
	node.rotation.y = rot_y
	node.scale = Vector3.ONE * scale_mult
	get_tree().current_scene.add_child(node)
	node.global_position = pos

func _scatter_zone_rocks():
	for zone_center in ZONES:
		# 4-6 large rocks per zone boundary
		for _i in randi_range(4, 6):
			var angle = randf_range(0, TAU)
			var dist  = randf_range(18.0, 28.0)
			var pos   = zone_center + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
			var rock  = ROCKS_LARGE[randi() % ROCKS_LARGE.size()]
			_place(rock, pos, randf_range(0, TAU), randf_range(0.8, 1.3))
		# 6-8 small rocks scattered inside zone
		for _i in randi_range(6, 8):
			var pos = zone_center + Vector3(randf_range(-22, 22), 0, randf_range(-22, 22))
			var rock = ROCKS_SMALL[randi() % ROCKS_SMALL.size()]
			_place(rock, pos, randf_range(0, TAU), randf_range(0.7, 1.1))
		# 2-3 tall rocks as landmarks
		for _i in randi_range(2, 3):
			var pos = zone_center + Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
			var rock = ROCKS_TALL[randi() % ROCKS_TALL.size()]
			_place(rock, pos, randf_range(0, TAU), randf_range(1.0, 1.5))

func _scatter_bushes_and_flowers():
	# Bushes along zone edges and between zones
	for _i in 40:
		var pos = Vector3(randf_range(-45, 45), 0, randf_range(-45, 45))
		# Skip the central camp area
		if pos.length() < 8.0:
			continue
		var bush = BUSHES[randi() % BUSHES.size()]
		_place(bush, pos, randf_range(0, TAU), randf_range(0.8, 1.2))

	# Flowers in clusters
	for _i in 30:
		var center = Vector3(randf_range(-40, 40), 0, randf_range(-40, 40))
		if center.length() < 6.0:
			continue
		for _j in randi_range(2, 4):
			var pos = center + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
			var flower = FLOWERS[randi() % FLOWERS.size()]
			_place(flower, pos, randf_range(0, TAU), randf_range(0.9, 1.1))

func _scatter_mushrooms():
	# Mushrooms near zone centers (under tree canopies)
	for zone_center in ZONES:
		for _i in randi_range(5, 8):
			var pos = zone_center + Vector3(randf_range(-18, 18), 0, randf_range(-18, 18))
			var m = MUSHROOMS[randi() % MUSHROOMS.size()]
			_place(m, pos, randf_range(0, TAU), randf_range(0.7, 1.0))

func _scatter_grass():
	for _i in 60:
		var pos = Vector3(randf_range(-48, 48), 0, randf_range(-48, 48))
		if pos.length() < 5.0:
			continue
		var g = GRASS_LIST[randi() % GRASS_LIST.size()]
		_place(g, pos, randf_range(0, TAU), randf_range(0.9, 1.3))

func _place_log_stacks():
	# Near sawmill at (-8, 0, 0)
	var sawmill = Vector3(-8, 0, 0)
	for i in 4:
		var angle = TAU * float(i) / 4.0 + randf_range(-0.3, 0.3)
		var pos = sawmill + Vector3(cos(angle) * randf_range(3, 5), 0, sin(angle) * randf_range(3, 5))
		var log = LOGS[randi() % LOGS.size()]
		_place(log, pos, randf_range(0, TAU), randf_range(0.9, 1.1))
	# A few stumps near sawmill too
	for _i in 3:
		var pos = sawmill + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
		var s = STUMPS[randi() % STUMPS.size()]
		_place(s, pos, randf_range(0, TAU), randf_range(0.8, 1.0))

func _place_camp_fences():
	# Fence line around the camp area (sell zone at origin, campfire at (3,0,9))
	var fence_positions = [
		Vector3(-5, 0, -4), Vector3(-3, 0, -4), Vector3(-1, 0, -4),
		Vector3(1, 0, -4),  Vector3(3, 0, -4),  Vector3(5, 0, -4),
		Vector3(-5, 0, 12), Vector3(-3, 0, 12),  Vector3(-1, 0, 12),
		Vector3(1, 0, 12),  Vector3(3, 0, 12),   Vector3(5, 0, 12),
		Vector3(-6, 0, -2), Vector3(-6, 0, 0),   Vector3(-6, 0, 2),
		Vector3(-6, 0, 4),  Vector3(-6, 0, 6),   Vector3(-6, 0, 8),
		Vector3(7, 0, -2),  Vector3(7, 0, 0),    Vector3(7, 0, 2),
		Vector3(7, 0, 4),   Vector3(7, 0, 6),    Vector3(7, 0, 8),
	]
	for pos in fence_positions:
		var fence = FENCES[randi() % FENCES.size()]
		_place(fence, pos, 0.0, 1.0)

func _scatter_stumps():
	# Stumps scattered around world as if trees were cut before
	for _i in 15:
		var pos = Vector3(randf_range(-45, 45), 0, randf_range(-45, 45))
		if pos.length() < 10.0:
			continue
		var s = STUMPS[randi() % STUMPS.size()]
		_place(s, pos, randf_range(0, TAU), randf_range(0.8, 1.1))
