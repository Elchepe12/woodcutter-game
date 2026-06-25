extends Node3D

const ZONES = {
	"pino": {
		"position": Vector3(-20, 0, -20),
		"size": Vector3(24, 10, 24),
		"label": "Bosque de Pinos",
		"tree_weights": [0.70, 0.20, 0.10, 0.00],
		"tree_count": 28,
	},
	"roble": {
		"position": Vector3(20, 0, -20),
		"size": Vector3(24, 10, 24),
		"label": "Bosque de Robles",
		"tree_weights": [0.10, 0.20, 0.60, 0.10],
		"tree_count": 22,
	},
	"abedul": {
		"position": Vector3(-20, 0, 20),
		"size": Vector3(24, 10, 24),
		"label": "Arboleda de Abedules",
		"tree_weights": [0.15, 0.65, 0.15, 0.05],
		"tree_count": 25,
	},
	"secuoya": {
		"position": Vector3(20, 0, 20),
		"size": Vector3(20, 10, 20),
		"label": "Reserva de Secuoyas",
		"tree_weights": [0.05, 0.05, 0.15, 0.75],
		"tree_count": 12,
	},
}

var current_zone: String = ""

signal zone_changed(zone_id: String, zone_label: String)

func _ready():
	add_to_group("zone_manager")
	_build_zones()

func _build_zones():
	for zone_id in ZONES:
		var data = ZONES[zone_id]

		var area = Area3D.new()
		area.name = "Zone_" + zone_id
		add_child(area)
		area.global_position = data["position"]

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = data["size"]
		shape.shape = box
		area.add_child(shape)

		area.body_entered.connect(_on_zone_entered.bind(zone_id))
		area.body_exited.connect(_on_zone_exited.bind(zone_id))

		var spawner = Node3D.new()
		spawner.set_script(load("res://scripts/ForestRenderer.gd"))
		spawner.zone_size    = Vector2(data["size"].x, data["size"].z)
		spawner.tree_count   = data["tree_count"]
		spawner.tree_weights = data["tree_weights"]
		spawner.zone_id      = zone_id
		area.add_child(spawner)

const ZONE_XP_BONUS_LABEL = {
	"pino": "+50% XP en Pino",
	"roble": "+50% XP en Roble",
	"abedul": "+50% XP en Abedul",
	"secuoya": "+50% XP en Secuoya",
}

func _on_zone_entered(body: Node3D, zone_id: String):
	if not body.is_in_group("player"):
		return
	current_zone = zone_id
	zone_changed.emit(zone_id, ZONES[zone_id]["label"])
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and ZONE_XP_BONUS_LABEL.has(zone_id):
		hud.queue_notification(ZONE_XP_BONUS_LABEL[zone_id])

func _on_zone_exited(body: Node3D, zone_id: String):
	if not body.is_in_group("player") or current_zone != zone_id:
		return
	current_zone = ""
	zone_changed.emit("", "")
