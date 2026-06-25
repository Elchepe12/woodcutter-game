extends Area3D

@onready var sign_label: Label3D = $Label3D

const WOOD_PRICES = { 0: 6, 1: 8, 2: 10, 3: 25, "plank_0": 9, "plank_1": 12, "plank_2": 15, "plank_3": 38 }

var player_inside: bool = false

signal sale_completed(coins_earned: int)

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sign_label.text = "ZONA DE VENTA"
	_build_floor_marker()

func _build_floor_marker() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(5.5, 5.5)
	mi.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.55, 0.22, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness    = 1.0
	mi.material_override = mat
	mi.position = Vector3(0, 0.02, 0)
	add_child(mi)

	# Four corner posts
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(1.0, 0.85, 0.1)
	post_mat.emission_enabled = true
	post_mat.emission = Color(1.0, 0.85, 0.1)
	post_mat.emission_energy_multiplier = 0.6
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var post := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.06; cm.bottom_radius = 0.06; cm.height = 2.5
			post.mesh = cm
			post.material_override = post_mat
			post.position = Vector3(sx * 2.6, 1.25, sz * 2.6)
			add_child(post)

func _on_body_entered(body: Node3D):
	if not body.is_in_group("player"):
		return
	player_inside = true
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_sell_prompt(true, _calculate_total())

func _on_body_exited(body: Node3D):
	if not body.is_in_group("player"):
		return
	player_inside = false
	sign_label.text = "ZONA DE VENTA"
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_sell_prompt(false, 0)

func _process(_delta):
	if not player_inside:
		return
	var mult := _get_price_multiplier()
	var total := _calculate_total(mult)
	var mult_text := " (x%.1f!)" % mult if mult > 1.0 else ""
	sign_label.text = "ZONA DE VENTA\n[F] Vender $%d%s" % [total, mult_text]
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_sell_prompt(true, total)
	if Input.is_action_just_pressed("sell"):
		_execute_sale()

func _execute_sale():
	var mult := _get_price_multiplier()
	var total := _calculate_total(mult)
	var sold_items := Inventory.get_all()
	var hud = get_tree().get_first_node_in_group("hud")

	if total == 0:
		if hud:
			hud.queue_notification("Sin madera para vender")
		return

	for type in Inventory.get_all().keys():
		Inventory.remove_wood(type, Inventory.get_amount(type))

	ProgressSystem.add_coins(total)
	DailyContracts.record_sale(sold_items, total)
	Tutorial.record_sale()
	StatsTracker.record_sale(total, mult > 1.0)
	sale_completed.emit(total)

	var msg := "+$%d vendidos!" % total
	if mult > 1.0:
		msg += " (HORA PUNTA!)"

	# Night achievement
	var dnc = get_tree().get_first_node_in_group("day_night_cycle")
	if dnc and dnc.get_hour() >= 22:
		AchievementSystem.unlock("nocturno")

	if hud:
		hud.queue_notification(msg)

func _calculate_total(mult: float = 1.0) -> int:
	var total := 0
	for type in Inventory.get_all():
		total += Inventory.get_amount(type) * WOOD_PRICES.get(type, 5)
	return int(float(total) * mult)

func _get_price_multiplier() -> float:
	var dnc = get_tree().get_first_node_in_group("day_night_cycle")
	if dnc and dnc.has_method("get_price_multiplier"):
		return dnc.get_price_multiplier()
	return 1.0
