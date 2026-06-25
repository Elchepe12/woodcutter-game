extends Node

const SAVE_PATH := "user://tutorial_state.cfg"

var step := 0
var completed := false

signal tutorial_changed(text: String, should_show: bool)

func _ready() -> void:
	_load_state()
	Inventory.inventory_changed.connect(_check_inventory)
	ProgressSystem.upgrade_purchased.connect(_check_upgrade)
	if not completed:
		_emit_current()
	else:
		tutorial_changed.emit("", false)

func _check_inventory() -> void:
	if step == 0 and Inventory.total_items > 0:
		step = 1
		_save_state()
		_emit_current()

func record_processed() -> void:
	if step == 1:
		step = 2
		_save_state()
		_emit_current()

func record_sale() -> void:
	if step == 2:
		step = 3
		_save_state()
		_emit_current()

func _check_upgrade(_upgrade_type: String, _new_level: int) -> void:
	if step == 3 and not completed:
		completed = true
		_save_state()
		tutorial_changed.emit("Tutorial completado! Presiona [H] para ver controles.", true)
		get_tree().create_timer(4.0).timeout.connect(func():
			tutorial_changed.emit("", false)
		)

func _emit_current() -> void:
	var messages := [
		"1/4  [LMB] Corta un arbol.",
		"2/4  [E] Lleva los troncos al ASERRADERO.",
		"3/4  [F] Ve a la ZONA DE VENTA y vende.",
		"4/4  [E] Entra a la TIENDA y mejora tu hacha.",
	]
	if step < messages.size():
		tutorial_changed.emit(messages[step], true)

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("tutorial", "step", step)
	config.set_value("tutorial", "completed", completed)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	step = clampi(int(config.get_value("tutorial", "step", 0)), 0, 4)
	completed = bool(config.get_value("tutorial", "completed", false))
