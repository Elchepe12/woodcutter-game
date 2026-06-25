extends Area3D

var wood_type: int = 0

const WOOD_NAMES := { 0: "Pino", 1: "Abedul", 2: "Roble", 3: "Secuoya" }
const WOOD_COLORS := {
	0: Color(0.42, 0.22, 0.09),
	1: Color(0.72, 0.66, 0.48),
	2: Color(0.28, 0.14, 0.06),
	3: Color(0.48, 0.12, 0.05),
}

@onready var label: Label3D = $Label3D

var _picking_up := false

const DESPAWN_TIME := 55.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_visual()
	label.visible = false
	# Bob up/down gently
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", 0.35, 0.7).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", 0.1, 0.7).set_ease(Tween.EASE_IN_OUT)
	# Despawn after DESPAWN_TIME seconds
	get_tree().create_timer(DESPAWN_TIME - 10.0).timeout.connect(_start_despawn_warning)
	get_tree().create_timer(DESPAWN_TIME).timeout.connect(queue_free)

func _start_despawn_warning() -> void:
	if not is_instance_valid(self):
		return
	label.text    = "Expira pronto!"
	label.visible = true

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or _picking_up:
		return
	if Inventory.is_full():
		label.text = "Inventario lleno!"
		label.visible = true
		return
	_picking_up = true
	label.text = "+1 %s" % WOOD_NAMES.get(wood_type, "tronco")
	label.visible = true
	await get_tree().create_timer(0.25).timeout
	Inventory.add_wood(wood_type, 1)
	StatsTracker.record_log_collected()
	queue_free()

func _build_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	var log_mesh := CylinderMesh.new()
	log_mesh.top_radius = 0.16
	log_mesh.bottom_radius = 0.20
	log_mesh.height = 1.25
	mesh_instance.mesh = log_mesh
	mesh_instance.rotation_degrees.z = 90.0
	var material := StandardMaterial3D.new()
	material.albedo_color = WOOD_COLORS.get(wood_type, Color.SADDLE_BROWN)
	material.roughness = 0.92
	mesh_instance.material_override = material
	add_child(mesh_instance)
