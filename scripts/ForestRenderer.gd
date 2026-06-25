extends Node3D

@export var tree_count: int = 60
@export var zone_size: Vector2 = Vector2(25, 25)
@export var tree_weights: Array = [0.4, 0.3, 0.2, 0.1]
@export var respawn_delay: float = 35.0
var zone_id: String = ""

const ZONE_PRIMARY_TYPE := { "pino": 0, "abedul": 1, "roble": 2, "secuoya": 3 }
const GIANT_CHANCE := 0.05

const MIN_DISTANCE = 4.5
const WOOD_SCENE = preload("res://scenes/WoodTree.tscn")

var _tree_data: Array = []

func _ready():
	call_deferred("_spawn_all")

func _spawn_all():
	var placed: Array[Vector2] = []
	for _i in tree_count:
		var pos2d = _find_valid_pos(placed)
		if pos2d == Vector2.INF:
			continue
		placed.append(pos2d)
		var type = _weighted_type()
		var world_pos = global_position + Vector3(pos2d.x, 0, pos2d.y)
		var idx := _tree_data.size()
		_tree_data.append({ "pos": world_pos, "type": type, "node": null })
		var node = _create_tree(type, world_pos, idx)
		_tree_data[idx]["node"] = node

func _create_tree(type: int, world_pos: Vector3, idx: int) -> Node:
	var tree = WOOD_SCENE.instantiate()
	tree.wood_type = type
	var giant := randf() < GIANT_CHANCE
	tree.is_giant = giant
	tree.rotation.y = randf_range(0, TAU)
	tree.scale = Vector3.ONE * (randf_range(1.8, 2.2) if giant else randf_range(0.80, 1.10))
	get_tree().current_scene.add_child(tree)
	tree.global_position = world_pos
	tree.add_to_group("wood")
	var zid := zone_id
	tree.wood_cut.connect(func(t: int, _a: int):
		var base_xp := 4 + t * 2
		var bonus_mult := 1.5 if (zid != "" and ZONE_PRIMARY_TYPE.get(zid, -1) == t) else 1.0
		ProgressSystem.add_cutting_xp(int(base_xp * bonus_mult))
	)
	tree.tree_exiting.connect(_on_tree_removed.bind(idx))
	return tree

func _on_tree_removed(idx: int):
	if idx < _tree_data.size():
		_tree_data[idx]["node"] = null
	get_tree().create_timer(respawn_delay).timeout.connect(func(): _respawn(idx))

func _respawn(idx: int):
	if idx >= _tree_data.size() or not is_instance_valid(self):
		return
	var data = _tree_data[idx]
	var node = _create_tree(data["type"], data["pos"], idx)
	_tree_data[idx]["node"] = node

func _find_valid_pos(placed: Array[Vector2]) -> Vector2:
	for _attempt in 80:
		var candidate = Vector2(
			randf_range(-zone_size.x / 2, zone_size.x / 2),
			randf_range(-zone_size.y / 2, zone_size.y / 2)
		)
		var valid = true
		for p in placed:
			if candidate.distance_to(p) < MIN_DISTANCE:
				valid = false
				break
		if valid:
			return candidate
	return Vector2.INF

func _weighted_type() -> int:
	if tree_weights.is_empty():
		return 0
	var roll = randf()
	var acc = 0.0
	for i in tree_weights.size():
		acc += float(tree_weights[i])
		if roll < acc:
			return i
	return 0
