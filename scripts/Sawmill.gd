extends Area3D

const RAW_WOOD_TYPES := [0, 1, 2, 3]
const PROCESS_TIME   := 2.5

@onready var sawmill_sign: Label3D = $Label3D

var player_inside     := false
var processing        := false
var _blade_spin: float = 0.0
var _process_elapsed: float = 0.0
var _total_to_process: int = 0
var _blade_node: MeshInstance3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sawmill_sign.text = "ASERRADERO\n[E] Procesar madera"
	_build_visuals()

func _build_visuals() -> void:
	var wood_mat  := _make_mat(Color(0.30, 0.15, 0.06), 0.9, 0.0)
	var metal_mat := _make_mat(Color(0.42, 0.46, 0.48), 0.35, 0.8)
	_add_box("Platform", Vector3(5.0, 0.25, 3.0), Vector3(0, 0.12, 0), wood_mat)
	_add_box("SawBench", Vector3(3.6, 0.85, 0.9), Vector3(0, 0.55, 0), wood_mat)
	_add_box("LogRack",  Vector3(1.2, 0.7,  1.8), Vector3(-1.8, 0.48, 0.45), wood_mat)
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var blade_mesh         := CylinderMesh.new()
	blade_mesh.top_radius    = 0.58
	blade_mesh.bottom_radius = 0.58
	blade_mesh.height        = 0.08
	blade.mesh               = blade_mesh
	blade.material_override  = metal_mat
	blade.position           = Vector3(0.35, 1.02, 0)
	blade.rotation_degrees.x = 90.0
	add_child(blade)
	_blade_node = blade

func _make_mat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness    = roughness
	mat.metallic     = metallic
	return mat

func _add_box(node_name: String, box_size: Vector3, pos: Vector3, material: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var box := BoxMesh.new()
	box.size = box_size
	mi.mesh = box
	mi.material_override = material
	mi.position = pos
	add_child(mi)

func _process(delta: float) -> void:
	if _blade_node and processing:
		_blade_spin += delta * 720.0
		_blade_node.rotation_degrees.z = _blade_spin
		_process_elapsed += delta
		var remaining := maxf(0.0, PROCESS_TIME - _process_elapsed)
		sawmill_sign.text = "ASERRADERO\nProcesando %.1fs..." % remaining
		if _process_elapsed >= PROCESS_TIME:
			_finish_processing()
		return

	if player_inside and not processing and Input.is_action_just_pressed("interact"):
		_try_start_processing()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _try_start_processing() -> void:
	_total_to_process = 0
	for wood_type in RAW_WOOD_TYPES:
		_total_to_process += Inventory.get_amount(wood_type)
	if _total_to_process == 0:
		_show_message("Sin troncos para procesar")
		return
	processing = true
	_process_elapsed = 0.0
	_show_message("Procesando %d troncos..." % _total_to_process)

func _finish_processing() -> void:
	var converted := 0
	for wood_type in RAW_WOOD_TYPES:
		var amount := Inventory.get_amount(wood_type)
		if amount <= 0:
			continue
		Inventory.remove_wood(wood_type, amount)
		Inventory.add_wood("plank_%d" % wood_type, amount)
		converted += amount
	Tutorial.record_processed()
	StatsTracker.record_planks(converted)
	processing = false
	sawmill_sign.text = "ASERRADERO\n[E] Procesar madera"
	_show_message("%d troncos -> tablones (+50%% valor)!" % converted)

func _show_message(message: String) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.queue_notification(message)
