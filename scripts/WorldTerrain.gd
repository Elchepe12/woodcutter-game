extends MeshInstance3D

const ZONE_PATCHES = [
	{ "pos": Vector3(-20, 0.005, -20), "color": Color(0.12, 0.28, 0.10), "size": 28.0 },  # pino — bosque oscuro
	{ "pos": Vector3( 20, 0.005, -20), "color": Color(0.18, 0.35, 0.08), "size": 26.0 },  # roble — verde oscuro
	{ "pos": Vector3(-20, 0.005,  20), "color": Color(0.30, 0.46, 0.18), "size": 26.0 },  # abedul — verde claro
	{ "pos": Vector3( 20, 0.005,  20), "color": Color(0.22, 0.24, 0.12), "size": 24.0 },  # secuoya — tierra oscura
]

func _ready():
	# Main ground plane
	var plane := PlaneMesh.new()
	plane.size = Vector2(140, 140)
	mesh = plane

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.32, 0.14)
	mat.roughness = 1.0
	material_override = mat

	# Zone color patches
	for patch in ZONE_PATCHES:
		var mi  := MeshInstance3D.new()
		var pm  := PlaneMesh.new()
		pm.size = Vector2(patch.size, patch.size)
		mi.mesh = pm
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = patch.color
		pmat.roughness    = 1.0
		mi.material_override = pmat
		mi.position = patch.pos
		add_child(mi)

	# Central clearing near spawn (lighter grass)
	var center_mi  := MeshInstance3D.new()
	var center_pm  := PlaneMesh.new()
	center_pm.size = Vector2(18, 18)
	center_mi.mesh = center_pm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.24, 0.40, 0.16)
	cmat.roughness    = 1.0
	center_mi.material_override = cmat
	center_mi.position = Vector3(0, 0.004, 0)
	add_child(center_mi)
