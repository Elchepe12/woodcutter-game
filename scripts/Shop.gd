# Shop.gd — adjunta al Area3D de la tienda
extends Area3D

@onready var shop_sign: Label3D = $Label3D

var player_inside: bool = false
var shop_ui = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	shop_sign.text = "TIENDA\n[E] Entrar"
	_build_structure()

func _build_structure() -> void:
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.48, 0.36, 0.20)
	wall_mat.roughness    = 0.9

	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.28, 0.16, 0.08)
	roof_mat.roughness    = 0.95

	# Walls (left/right, back)
	for pos_x in [-1.8, 1.8]:
		_add_box(Vector3(0.2, 2.5, 3.6), Vector3(pos_x, 1.25, 0), wall_mat)
	_add_box(Vector3(3.8, 2.5, 0.2), Vector3(0, 1.25, -1.8), wall_mat)

	# Roof
	var roof := MeshInstance3D.new()
	var rm   := PrismMesh.new()
	rm.size  = Vector3(4.5, 1.2, 4.5)
	roof.mesh = rm
	roof.material_override = roof_mat
	roof.position = Vector3(0, 3.0, 0)
	add_child(roof)

	# Counter inside
	var counter_mat := StandardMaterial3D.new()
	counter_mat.albedo_color = Color(0.38, 0.22, 0.10)
	_add_box(Vector3(3.0, 0.85, 0.4), Vector3(0, 0.42, -0.8), counter_mat)

func _add_box(sz: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body: Node3D):
	if body.is_in_group("player"):
		player_inside = false
		_close_shop()

func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		if shop_ui and shop_ui.visible:
			_close_shop()
		else:
			_open_shop()

func _open_shop():
	if not shop_ui:
		var scene = load("res://scenes/ShopUI.tscn")
		shop_ui = scene.instantiate()
		get_tree().root.add_child(shop_ui)
	shop_ui.open()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close_shop():
	if shop_ui and shop_ui.visible:
		shop_ui.close()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
