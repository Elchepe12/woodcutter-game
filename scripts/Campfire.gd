extends Node3D

var _flicker_time: float = 0.0
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	_build_visual()

func _build_visual() -> void:
	# Stone ring
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.4, 0.38, 0.35)
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var stone := MeshInstance3D.new()
		var sm    := SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.24
		stone.mesh = sm
		stone.material_override = stone_mat
		stone.position = Vector3(cos(angle) * 0.55, 0.08, sin(angle) * 0.55)
		add_child(stone)

	# Logs in the fire
	var log_mat := StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.25, 0.12, 0.05)
	for i in 3:
		var angle := TAU * float(i) / 3.0
		var log := MeshInstance3D.new()
		var cm  := CylinderMesh.new()
		cm.top_radius = 0.06; cm.bottom_radius = 0.06; cm.height = 1.0
		log.mesh = cm
		log.material_override = log_mat
		log.position = Vector3(0, 0.06, 0)
		log.rotation = Vector3(deg_to_rad(80), angle, 0)
		add_child(log)

	# Embers glow
	var embers := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15; sphere.height = 0.3
	embers.mesh = sphere
	var em_mat := StandardMaterial3D.new()
	em_mat.albedo_color = Color(1.0, 0.4, 0.05)
	em_mat.emission_enabled = true
	em_mat.emission = Color(1.0, 0.3, 0.0)
	em_mat.emission_energy_multiplier = 3.0
	embers.material_override = em_mat
	embers.position = Vector3(0, 0.15, 0)
	add_child(embers)

func _process(delta: float) -> void:
	if not light:
		return
	_flicker_time += delta * 8.0
	var flicker := sin(_flicker_time) * 0.15 + sin(_flicker_time * 2.3) * 0.08
	light.light_energy  = 2.5 + flicker
	light.omni_range    = 8.0 + flicker * 2.0
