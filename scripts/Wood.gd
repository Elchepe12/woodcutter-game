extends StaticBody3D

enum WoodType { PINE, BIRCH, OAK, REDWOOD }

@export var wood_type: WoodType = WoodType.PINE
@export var max_health: float = 100.0
@export var is_giant: bool = false

var health: float
var _trunk_material: StandardMaterial3D = null

const WOOD_DATA = {
	WoodType.PINE:    { "name": "Pino",    "value": 6,  "hardness": 0.6, "health": 80.0,  "axe_level": 0 },
	WoodType.BIRCH:   { "name": "Abedul",  "value": 8,  "hardness": 0.8, "health": 110.0, "axe_level": 0 },
	WoodType.OAK:     { "name": "Roble",   "value": 10, "hardness": 1.0, "health": 160.0, "axe_level": 1 },
	WoodType.REDWOOD: { "name": "Secuoya", "value": 25, "hardness": 2.0, "health": 260.0, "axe_level": 2 },
}

const TREE_MODELS = {
	WoodType.PINE: [
		"res://assets/trees/pine/Flat_Tree_Pine_large.glb",
		"res://assets/trees/pine/Flat_Tree_Pine_medium.glb",
		"res://assets/trees/pine/Flat_Tree_Pine_small.glb",
		"res://assets/trees/pine/Flat_Tree_Pine_hero.glb",
	],
	WoodType.BIRCH: [
		"res://assets/trees/birch/Flat_Tree_Birch_large_green.glb",
		"res://assets/trees/birch/Flat_Tree_Birch_medium_green.glb",
		"res://assets/trees/birch/Flat_Tree_Birch_small_green.glb",
		"res://assets/trees/birch/Flat_Tree_Birch_hero_green.glb",
	],
	WoodType.OAK: [
		"res://assets/trees/oak/Flat_Tree_Oak_large_green.glb",
		"res://assets/trees/oak/Flat_Tree_Oak_medium_green.glb",
		"res://assets/trees/oak/Flat_Tree_Oak_small_green.glb",
		"res://assets/trees/oak/Flat_Tree_Oak_hero_green.glb",
	],
	WoodType.REDWOOD: [
		"res://assets/trees/redwood/Flat_Tree_Spruce_large.glb",
		"res://assets/trees/redwood/Flat_Tree_Spruce_medium.glb",
	],
}

const TREE_COLORS = {
	WoodType.PINE:    Color(0.15, 0.45, 0.15),
	WoodType.BIRCH:   Color(0.55, 0.75, 0.45),
	WoodType.OAK:     Color(0.20, 0.55, 0.10),
	WoodType.REDWOOD: Color(0.60, 0.20, 0.10),
}

signal wood_cut(type: WoodType, amount: int)

const STUMP_MODEL = "res://assets/trees/extras/Flat_Tree_Stump.glb"
const LOG_SCENE = preload("res://scenes/LogPickup.tscn")

func _ready():
	max_health = WOOD_DATA[wood_type]["health"] * (3.0 if is_giant else 1.0)
	health = max_health
	_load_visual()
	_add_collision()

func _load_visual():
	var paths = TREE_MODELS.get(wood_type, [])
	if not paths.is_empty():
		var path = paths[randi() % paths.size()]
		var packed = load(path)
		if packed:
			var visual = packed.instantiate()
			if wood_type == WoodType.REDWOOD:
				visual.scale = Vector3(1.4, 1.8, 1.4)
			add_child(visual)
			return
	_add_procedural_tree()

func _add_procedural_tree():
	var trunk_color = Color(0.40, 0.25, 0.10)
	var crown_color = TREE_COLORS.get(wood_type, Color(0.2, 0.5, 0.1))
	var height_mult = 1.8 if wood_type == WoodType.REDWOOD else 1.0

	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.28
	cyl.height = 2.5 * height_mult
	trunk.mesh = cyl
	trunk.position = Vector3(0, 1.25 * height_mult, 0)
	_trunk_material = StandardMaterial3D.new()
	_trunk_material.albedo_color = trunk_color
	trunk.material_override = _trunk_material
	add_child(trunk)

	var crown = MeshInstance3D.new()
	if wood_type == WoodType.PINE or wood_type == WoodType.REDWOOD:
		var cone = CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 1.2
		cone.height = 3.0 * height_mult
		crown.mesh = cone
	else:
		var sphere = SphereMesh.new()
		sphere.radius = 1.3
		sphere.height = 2.6
		crown.mesh = sphere
	crown.position = Vector3(0, 3.2 * height_mult, 0)
	var mat_crown = StandardMaterial3D.new()
	mat_crown.albedo_color = crown_color
	crown.material_override = mat_crown
	add_child(crown)

func _add_collision():
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.4
	shape.height = 3.0
	col.shape = shape
	col.position = Vector3(0, 1.5, 0)
	add_child(col)

func get_hardness() -> float:
	return WOOD_DATA[wood_type]["hardness"]

func get_required_axe_level() -> int:
	return WOOD_DATA[wood_type]["axe_level"]

func get_wood_name() -> String:
	return WOOD_DATA[wood_type]["name"]

func take_damage(damage: float):
	health -= damage
	_update_damage_visual()
	if health <= 0:
		_fall()

func _update_damage_visual():
	if _trunk_material == null:
		return
	var t = clampf(1.0 - (health / max_health), 0.0, 1.0)
	_trunk_material.albedo_color = Color(0.40, 0.25, 0.10).lerp(Color(0.80, 0.62, 0.40), t)

func on_cut_start():
	if has_node("CutEffect"):
		$CutEffect.start_cutting()

func on_cut_stop():
	if has_node("CutEffect"):
		$CutEffect.stop_cutting()

func _fall():
	health = 999.0

	for child in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)

	var fall_dir = _get_fall_direction()

	if has_node("CutEffect"):
		$CutEffect.stop_cutting()
		$CutEffect.play_fall()

	var target_rotation = rotation + Vector3(fall_dir.z * PI * 0.5, 0.0, -fall_dir.x * PI * 0.5)

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation", target_rotation, 1.4)

	await tween.finished
	_spawn_stump()

	await get_tree().create_timer(0.6).timeout
	var amount = randi_range(8, 12) if is_giant else randi_range(2, 5)
	_spawn_logs(amount)
	wood_cut.emit(wood_type, amount)
	DailyContracts.record_tree_cut(int(wood_type))
	StatsTracker.record_tree_cut()
	if is_giant:
		AchievementSystem.unlock("gigante")
	queue_free()

func _spawn_stump():
	var packed = load(STUMP_MODEL)
	if not packed:
		return
	var stump = packed.instantiate()
	get_tree().current_scene.add_child(stump)
	stump.global_position = global_position
	stump.rotation.y = rotation.y
	get_tree().create_timer(35.0).timeout.connect(stump.queue_free)

func _spawn_logs(amount: int):
	for i in amount:
		var log = LOG_SCENE.instantiate()
		log.wood_type = wood_type
		get_tree().current_scene.add_child(log)
		var angle = TAU * float(i) / float(amount) + randf_range(-0.3, 0.3)
		var offset = Vector3(cos(angle), 0.22, sin(angle)) * randf_range(0.8, 2.0)
		log.global_position = global_position + offset
		log.rotation.y = randf_range(0.0, TAU)

func _get_fall_direction() -> Vector3:
	var player = get_tree().get_first_node_in_group("player")
	var dir = Vector3.ZERO

	if player:
		dir = global_position - player.global_position
		dir.y = 0.0
		if dir.length() > 0.1:
			dir = dir.normalized()

	if dir.length() < 0.1:
		dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()

	var angle_offset = randf_range(-0.35, 0.35)
	dir = dir.rotated(Vector3.UP, angle_offset)
	return dir
