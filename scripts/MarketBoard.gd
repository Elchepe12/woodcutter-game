extends Node3D

const WOOD_PRICES  = { 0: 6,  1: 8,  2: 10, 3: 25  }
const PLANK_PRICES = { 0: 9, 1: 12, 2: 15, 3: 38  }
const WOOD_NAMES   = ["Pino", "Abedul", "Roble", "Secuoya"]

@onready var board_label: Label3D = $BoardLabel

func _ready() -> void:
	_build_board_mesh()
	_refresh_text()
	# Update when rush hour changes
	get_tree().create_timer(1.0).timeout.connect(_start_periodic_refresh)

func _start_periodic_refresh():
	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	timer.timeout.connect(_refresh_text)
	add_child(timer)

func _refresh_text() -> void:
	var dnc = get_tree().get_first_node_in_group("day_night_cycle")
	var mult := 1.0
	var rush_text := ""
	if dnc and dnc.has_method("get_price_multiplier"):
		mult = dnc.get_price_multiplier()
	if mult > 1.0:
		rush_text = "\n[HORA PUNTA x%.1f!]" % mult

	var lines := ["PRECIOS DEL MERCADO" + rush_text, ""]
	for i in WOOD_NAMES.size():
		var raw   := int(float(WOOD_PRICES[i])  * mult)
		var plank := int(float(PLANK_PRICES[i]) * mult)
		lines.append("%s: $%d / Tablon: $%d" % [WOOD_NAMES[i], raw, plank])
	board_label.text = "\n".join(lines)

func _build_board_mesh() -> void:
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.30, 0.18, 0.08)
	for x in [-0.85, 0.85]:
		var post := MeshInstance3D.new()
		var cyl  := CylinderMesh.new()
		cyl.top_radius    = 0.07
		cyl.bottom_radius = 0.07
		cyl.height        = 2.4
		post.mesh = cyl
		post.position = Vector3(x, 1.2, 0)
		post.material_override = post_mat
		add_child(post)
	var board_mat := StandardMaterial3D.new()
	board_mat.albedo_color = Color(0.55, 0.38, 0.18)
	var board := MeshInstance3D.new()
	var box   := BoxMesh.new()
	box.size  = Vector3(2.0, 0.8, 0.08)
	board.mesh = box
	board.position = Vector3(0, 2.0, 0)
	board.material_override = board_mat
	add_child(board)
