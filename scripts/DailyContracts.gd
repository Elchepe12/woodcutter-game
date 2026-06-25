extends Node

const WOOD_NAMES := { 0: "Pino", 1: "Abedul", 2: "Roble", 3: "Secuoya" }
const WOOD_REWARDS := { 0: 45, 1: 60, 2: 80, 3: 130 }
const SAVE_PATH := "user://daily_contracts.cfg"

var contracts: Array[Dictionary] = []
var _day_key := ""

signal contracts_changed
signal contract_completed(contract: Dictionary)

func _ready() -> void:
	_load_state()
	_refresh_for_today()
	var timer := Timer.new()
	timer.wait_time = 60.0
	timer.autostart = true
	timer.timeout.connect(_refresh_for_today)
	add_child(timer)

func _refresh_for_today() -> void:
	var date := Time.get_date_dict_from_system()
	var today := "%04d-%02d-%02d" % [date.year, date.month, date.day]
	if today == _day_key:
		return
	_day_key = today
	contracts = _build_contracts(today)
	_save_state()
	contracts_changed.emit()

func _build_contracts(seed_text: String) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_text.hash()
	var wood_types := [0, 1, 2, 3]
	var result: Array[Dictionary] = []

	# Sell contract
	var pick := rng.randi_range(0, wood_types.size() - 1)
	var wood_type: int = wood_types.pop_at(pick)
	var sell_target := rng.randi_range(10, 22) + wood_type * 2
	result.append({
		"kind": "sell_wood", "wood_type": wood_type, "target": sell_target,
		"progress": 0, "reward": WOOD_REWARDS[wood_type] + sell_target * 2,
		"title": "Vende %d %s" % [sell_target, WOOD_NAMES[wood_type]], "completed": false,
	})

	# Cut trees contract
	var cut_type: int = wood_types[rng.randi_range(0, wood_types.size() - 1)]
	var cut_target := rng.randi_range(5, 12) + cut_type
	result.append({
		"kind": "cut_trees", "wood_type": cut_type, "target": cut_target,
		"progress": 0, "reward": WOOD_REWARDS[cut_type] + cut_target * 3,
		"title": "Tala %d %s" % [cut_target, WOOD_NAMES[cut_type]], "completed": false,
	})

	# Earn coins contract
	var earn_target := rng.randi_range(80, 200)
	result.append({
		"kind": "earn_coins", "target": earn_target, "progress": 0,
		"reward": int(earn_target * 0.45), "title": "Gana $%d" % earn_target, "completed": false,
	})
	return result

func record_tree_cut(wood_type: int) -> void:
	var changed := false
	for contract in contracts:
		if contract.completed or contract.kind != "cut_trees":
			continue
		if contract.wood_type != wood_type:
			continue
		contract.progress = mini(contract.progress + 1, contract.target)
		changed = true
		if contract.progress >= contract.target:
			contract.completed = true
			ProgressSystem.add_coins(contract.reward)
			contract_completed.emit(contract.duplicate(true))
	if changed:
		_save_state()
		contracts_changed.emit()

func record_sale(sold_items: Dictionary, coins_earned: int) -> void:
	var changed := false
	for contract in contracts:
		if contract.completed:
			continue
		var increase := 0
		if contract.kind == "sell_wood":
			increase = int(sold_items.get(contract.wood_type, 0))
		elif contract.kind == "earn_coins":
			increase = coins_earned
		if increase <= 0:
			continue
		contract.progress = mini(contract.progress + increase, contract.target)
		changed = true
		if contract.progress >= contract.target:
			contract.completed = true
			ProgressSystem.add_coins(contract.reward)
			contract_completed.emit(contract.duplicate(true))
	if changed:
		_save_state()
		contracts_changed.emit()

func get_completion_count() -> int:
	var done := 0
	for c in contracts:
		if c.completed:
			done += 1
	return done

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("contracts", "day_key", _day_key)
	config.set_value("contracts", "entries", contracts)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	_day_key = str(config.get_value("contracts", "day_key", ""))
	var entries = config.get_value("contracts", "entries", [])
	if entries is Array:
		contracts.assign(entries)
