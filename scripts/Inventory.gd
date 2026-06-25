# Inventory.gd — Autoload
extends Node

var items: Dictionary = {}
var total_items: int = 0

const SAVE_PATH := "user://player_inventory.cfg"

signal inventory_changed

func _ready() -> void:
	_load_state()

func add_wood(type, amount: int) -> bool:
	var capacity = ProgressSystem.get_inventory_capacity()
	if total_items + amount > capacity:
		amount = capacity - total_items
		if amount <= 0:
			return false

	items[type] = items.get(type, 0) + amount
	total_items += amount
	_save_state()
	inventory_changed.emit()
	return true

func remove_wood(type, amount: int) -> bool:
	if items.get(type, 0) < amount:
		return false
	items[type] -= amount
	total_items -= amount
	if items[type] == 0:
		items.erase(type)
	_save_state()
	inventory_changed.emit()
	return true

func get_amount(type) -> int:
	return items.get(type, 0)

func get_all() -> Dictionary:
	return items.duplicate()

func is_full() -> bool:
	return total_items >= ProgressSystem.get_inventory_capacity()

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("inventory", "items", items)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved_items = config.get_value("inventory", "items", {})
	if not saved_items is Dictionary:
		return
	items = saved_items
	total_items = 0
	for amount in items.values():
		total_items += int(amount)
