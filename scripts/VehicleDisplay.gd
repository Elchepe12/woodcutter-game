extends Node3D

@onready var sign: Label3D = $Label3D

var _wood_material: StandardMaterial3D
var _metal_material: StandardMaterial3D
var _rubber_material: StandardMaterial3D

func _ready() -> void:
	_wood_material = _make_material(Color(0.32, 0.16, 0.07), 0.95, 0.0)
	_metal_material = _make_material(Color(0.14, 0.32, 0.42), 0.38, 0.72)
	_rubber_material = _make_material(Color(0.035, 0.04, 0.045), 0.9, 0.0)
	ProgressSystem.upgrade_purchased.connect(_on_upgrade_purchased)
	_rebuild()

func _on_upgrade_purchased(upgrade_type: String, _level: int) -> void:
	if upgrade_type == "vehicle":
		_rebuild()

func _rebuild() -> void:
	for child in get_children():
		if child != sign:
			child.queue_free()
	var level := ProgressSystem.vehicle_level
	var vehicle_name: String = ProgressSystem.VEHICLE_LEVELS[level]["name"]
	sign.text = "GARAJE\n%s" % vehicle_name
	if level == 0:
		return
	if level == 1:
		_build_wheelbarrow()
	elif level == 2:
		_build_pickup()
	else:
		_build_truck()

func _build_wheelbarrow() -> void:
	_add_box(Vector3(1.2, 0.38, 0.75), Vector3(0, 0.6, 0), _metal_material)
	_add_cylinder(Vector3(0, 0.28, 0.55), 0.28, 0.14, _rubber_material, Vector3(0, 0, 90))
	_add_box(Vector3(1.4, 0.08, 0.08), Vector3(0.9, 0.42, -0.22), _wood_material)
	_add_box(Vector3(1.4, 0.08, 0.08), Vector3(0.9, 0.42, 0.22), _wood_material)

func _build_pickup() -> void:
	_add_box(Vector3(2.6, 0.55, 1.35), Vector3(0, 0.65, 0), _metal_material)
	_add_box(Vector3(1.2, 0.5, 1.32), Vector3(-0.75, 1.05, 0), _metal_material)
	_add_box(Vector3(1.05, 0.38, 1.28), Vector3(0.82, 1.02, 0), _wood_material)
	_add_wheels(1.05, 0.62)

func _build_truck() -> void:
	_add_box(Vector3(4.3, 0.7, 1.65), Vector3(0, 0.78, 0), _metal_material)
	_add_box(Vector3(1.25, 0.8, 1.6), Vector3(-1.38, 1.35, 0), _metal_material)
	_add_box(Vector3(2.35, 0.75, 1.55), Vector3(0.85, 1.38, 0), _wood_material)
	_add_wheels(1.65, 0.78)

func _add_wheels(x_offset: float, z_offset: float) -> void:
	for x in [-x_offset, x_offset]:
		for z in [-z_offset, z_offset]:
			_add_cylinder(Vector3(x, 0.38, z), 0.35, 0.24, _rubber_material, Vector3(90, 0, 0))

func _add_box(box_size: Vector3, position_3d: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	visual.mesh = mesh
	visual.position = position_3d
	visual.material_override = material
	add_child(visual)

func _add_cylinder(position_3d: Vector3, radius: float, height: float, material: Material, rotation_deg: Vector3) -> void:
	var visual := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	visual.mesh = mesh
	visual.position = position_3d
	visual.rotation_degrees = rotation_deg
	visual.material_override = material
	add_child(visual)

func _make_material(color: Color, roughness_value: float, metallic_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	material.metallic = metallic_value
	return material
