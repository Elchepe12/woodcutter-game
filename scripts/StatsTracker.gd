extends Node

const SAVE_PATH := "user://stats.cfg"

var trees_cut:        int   = 0
var logs_collected:   int   = 0
var planks_processed: int   = 0
var total_coins:      int   = 0
var sales_made:       int   = 0
var distance_walked:  float = 0.0
var rush_hour_sales:  int   = 0

signal stats_changed

func _ready() -> void:
	_load()
	ProgressSystem.coins_changed.connect(_on_coins_changed)

func record_tree_cut() -> void:
	trees_cut += 1
	_check_achievements()
	_save()
	stats_changed.emit()

func record_log_collected() -> void:
	logs_collected += 1
	_save()

func record_planks(amount: int) -> void:
	planks_processed += amount
	_check_achievements()
	_save()

func record_sale(coins: int, during_rush: bool) -> void:
	sales_made += 1
	if during_rush:
		rush_hour_sales += 1
		AchievementSystem.unlock("hora_punta")
	AchievementSystem.unlock("primer_venta")
	if coins >= 500 or total_coins >= 500:
		AchievementSystem.unlock("rico")
	_check_achievements()
	_save()
	stats_changed.emit()

func add_distance(d: float) -> void:
	distance_walked += d

func _on_coins_changed(new_total: int) -> void:
	total_coins = new_total
	if total_coins >= 500:
		AchievementSystem.unlock("rico")

func _check_achievements() -> void:
	if trees_cut >= 1:
		AchievementSystem.unlock("primer_arbol")
	if trees_cut >= 10:
		AchievementSystem.unlock("hachero")
	if planks_processed >= 1:
		AchievementSystem.unlock("tablones")
	if planks_processed >= 20:
		AchievementSystem.unlock("aserrador")
	if DailyContracts.get_completion_count() >= 3:
		AchievementSystem.unlock("contratos")
	if Inventory.total_items >= ProgressSystem.get_inventory_capacity():
		AchievementSystem.unlock("acumulador")

func get_summary() -> String:
	var km := distance_walked / 1000.0
	return (
		"Arboles talados: %d\n" % trees_cut +
		"Troncos recogidos: %d\n" % logs_collected +
		"Tablones procesados: %d\n" % planks_processed +
		"Ventas realizadas: %d\n" % sales_made +
		"Ventas en hora punta: %d\n" % rush_hour_sales +
		"Distancia caminada: %.1f km" % km
	)

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "trees_cut", trees_cut)
	cfg.set_value("stats", "logs_collected", logs_collected)
	cfg.set_value("stats", "planks_processed", planks_processed)
	cfg.set_value("stats", "sales_made", sales_made)
	cfg.set_value("stats", "distance_walked", distance_walked)
	cfg.set_value("stats", "rush_hour_sales", rush_hour_sales)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	trees_cut        = int(cfg.get_value("stats", "trees_cut", 0))
	logs_collected   = int(cfg.get_value("stats", "logs_collected", 0))
	planks_processed = int(cfg.get_value("stats", "planks_processed", 0))
	sales_made       = int(cfg.get_value("stats", "sales_made", 0))
	distance_walked  = float(cfg.get_value("stats", "distance_walked", 0.0))
	rush_hour_sales  = int(cfg.get_value("stats", "rush_hour_sales", 0))
