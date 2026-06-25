extends Node

var coins: int = 0
var cutting_xp: int = 0
var cutting_level: int = 1

const SAVE_PATH := "user://player_progress.cfg"

const AXE_LEVELS = [
	{ "name": "Hacha de piedra", "damage": 20.0,  "upgrade_cost": 0   },
	{ "name": "Hacha de hierro", "damage": 40.0,  "upgrade_cost": 50  },
	{ "name": "Hacha de acero",  "damage": 70.0,  "upgrade_cost": 150 },
	{ "name": "Hacha de titan",  "damage": 120.0, "upgrade_cost": 400 },
]

const VEHICLE_LEVELS = [
	{ "name": "Sin vehiculo",  "capacity_bonus": 0,   "upgrade_cost": 0   },
	{ "name": "Carretilla",    "capacity_bonus": 25,  "upgrade_cost": 80  },
	{ "name": "Camioneta",     "capacity_bonus": 100, "upgrade_cost": 300 },
	{ "name": "Camion",        "capacity_bonus": 300, "upgrade_cost": 800 },
]

var axe_level: int = 0
var vehicle_level: int = 0

signal coins_changed(new_amount: int)
signal upgrade_purchased(upgrade_type: String, new_level: int)
signal cutting_xp_changed(xp: int, level: int, xp_to_next: int)
signal level_up(new_level: int)

func _ready() -> void:
	_load_state()

func get_axe_damage() -> float:
	return AXE_LEVELS[axe_level]["damage"]

func get_inventory_capacity() -> int:
	return 50 + VEHICLE_LEVELS[vehicle_level]["capacity_bonus"]

func add_coins(amount: int):
	if amount <= 0:
		return
	coins += amount
	_save_state()
	coins_changed.emit(coins)

func get_xp_to_next_level() -> int:
	return 30 + (cutting_level - 1) * 20

func get_cutting_speed_multiplier() -> float:
	return minf(1.0 + (cutting_level - 1) * 0.05, 1.75)

func add_cutting_xp(amount: int):
	if amount <= 0:
		return
	cutting_xp += amount
	var leveled_up := false
	while cutting_xp >= get_xp_to_next_level():
		cutting_xp -= get_xp_to_next_level()
		cutting_level += 1
		leveled_up = true
	cutting_xp_changed.emit(cutting_xp, cutting_level, get_xp_to_next_level())
	_save_state()
	if leveled_up:
		var coin_bonus := 10 * (cutting_level - 1)
		add_coins(coin_bonus)
		level_up.emit(cutting_level)
		if cutting_level >= 5:
			AchievementSystem.unlock("lv5")

func upgrade_axe() -> bool:
	if axe_level >= AXE_LEVELS.size() - 1:
		return false
	var cost = AXE_LEVELS[axe_level + 1]["upgrade_cost"]
	if coins < cost:
		return false
	coins -= cost
	axe_level += 1
	_save_state()
	coins_changed.emit(coins)
	upgrade_purchased.emit("axe", axe_level)
	AchievementSystem.unlock("primer_upgrade")
	return true

func upgrade_vehicle() -> bool:
	if vehicle_level >= VEHICLE_LEVELS.size() - 1:
		return false
	var cost = VEHICLE_LEVELS[vehicle_level + 1]["upgrade_cost"]
	if coins < cost:
		return false
	coins -= cost
	vehicle_level += 1
	_save_state()
	coins_changed.emit(coins)
	upgrade_purchased.emit("vehicle", vehicle_level)
	return true

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "coins", coins)
	config.set_value("progress", "axe_level", axe_level)
	config.set_value("progress", "vehicle_level", vehicle_level)
	config.set_value("progress", "cutting_xp", cutting_xp)
	config.set_value("progress", "cutting_level", cutting_level)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	coins = maxi(0, int(config.get_value("progress", "coins", 0)))
	axe_level = clampi(int(config.get_value("progress", "axe_level", 0)), 0, AXE_LEVELS.size() - 1)
	vehicle_level = clampi(int(config.get_value("progress", "vehicle_level", 0)), 0, VEHICLE_LEVELS.size() - 1)
	cutting_xp = maxi(0, int(config.get_value("progress", "cutting_xp", 0)))
	cutting_level = maxi(1, int(config.get_value("progress", "cutting_level", 1)))
