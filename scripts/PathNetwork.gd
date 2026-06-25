# PathNetwork.gd — adjunta a Node3D hijo de World
extends Node3D

const PATHS = [
	{ "from": Vector3(0, 0, 0),    "to": Vector3(-20, 0, -20), "width": 3.0 },
	{ "from": Vector3(0, 0, 0),    "to": Vector3( 20, 0, -20), "width": 3.0 },
	{ "from": Vector3(0, 0, 0),    "to": Vector3(-20, 0,  20), "width": 3.0 },
	{ "from": Vector3(0, 0, 0),    "to": Vector3( 20, 0,  20), "width": 3.0 },
	{ "from": Vector3(-20, 0, -20), "to": Vector3(20, 0, -20), "width": 2.0 },
	{ "from": Vector3(-20, 0, -20), "to": Vector3(-20, 0, 20), "width": 2.0 },
	{ "from": Vector3( 20, 0, -20), "to": Vector3( 20, 0, 20), "width": 2.0 },
	{ "from": Vector3(-20, 0,  20), "to": Vector3( 20, 0, 20), "width": 2.0 },
]

func _ready():
	for path_data in PATHS:
		_build_path(path_data)

func _build_path(data: Dictionary):
	var origin: Vector3 = data["from"]
	var target: Vector3 = data["to"]
	var width: float    = data["width"]

	var diff      = target - origin
	var length    = diff.length()
	var center    = (origin + target) / 2.0
	var direction = diff.normalized()
	var angle     = atan2(direction.x, direction.z)

	# Mesh visual de tierra
	var mesh_inst = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(width, length)
	mesh_inst.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.40, 0.25)
	mat.roughness = 0.95
	mesh_inst.material_override = mat
	mesh_inst.position = center + Vector3(0, 0.01, 0)
	mesh_inst.rotation.y = angle
	add_child(mesh_inst)

	# Area3D para detectar pisada y dar boost de velocidad
	var area = Area3D.new()
	var area_col = CollisionShape3D.new()
	var area_box = BoxShape3D.new()
	area_box.size = Vector3(width, 1.5, length)
	area_col.shape = area_box
	area.add_child(area_col)
	area.position = center + Vector3(0, 0.5, 0)
	area.rotation.y = angle
	area.body_entered.connect(_on_path_entered)
	area.body_exited.connect(_on_path_exited)
	add_child(area)

	_add_border_stones(origin, target, width)

func _on_path_entered(body: Node3D):
	if body.is_in_group("player") and body.has_method("set_on_path"):
		body.set_on_path(true)

func _on_path_exited(body: Node3D):
	if body.is_in_group("player") and body.has_method("set_on_path"):
		body.set_on_path(false)

func _add_border_stones(origin: Vector3, target: Vector3, width: float):
	var diff = target - origin
	var length = diff.length()
	var direction = diff.normalized()
	var right = direction.cross(Vector3.UP).normalized()
	var steps = int(length / 4.0)

	for i in steps:
		var t = (float(i) + 0.5) / float(steps)
		var base_pos = origin.lerp(target, t)

		for side in [-1, 1]:
			var stone = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = randf_range(0.1, 0.25)
			sphere.height = sphere.radius * 2.0
			stone.mesh = sphere
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.45, 0.42, 0.40)
			stone.material_override = mat
			stone.position = base_pos + right * (width / 2.0 + 0.3) * side
			stone.position.y = 0.05
			add_child(stone)
