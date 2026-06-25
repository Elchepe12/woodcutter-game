extends CanvasLayer

@onready var cutting_bar: ProgressBar      = $CuttingBar
@onready var cutting_label: Label          = $CuttingLabel
@onready var crosshair: Label              = $Crosshair
@onready var coins_label: Label            = $PanelLeft/VBox/CoinsLabel
@onready var capacity_label: Label         = $PanelLeft/VBox/CapacityLabel
@onready var inventory_list: VBoxContainer = $PanelLeft/VBox/InventoryList
@onready var axe_label: Label              = $PanelRight/VBox/AxeLabel
@onready var vehicle_label: Label          = $PanelRight/VBox/VehicleLabel
@onready var skill_label: Label            = $PanelRight/VBox/SkillLabel
@onready var sell_prompt: PanelContainer   = $SellPrompt
@onready var sell_prompt_label: Label      = $SellPrompt/Label
@onready var notification_label: Label     = $NotificationLabel
@onready var zone_label_node: Label        = $ZoneLabel
@onready var time_label: Label             = $TimeLabel
@onready var weather_label: Label          = $WeatherLabel
@onready var rush_hour_label: Label        = $RushHourLabel
@onready var stamina_bar: ProgressBar      = $StaminaBar
@onready var level_up_label: Label         = $LevelUpLabel
@onready var achievement_panel: PanelContainer = $AchievementPanel
@onready var achievement_label: Label      = $AchievementPanel/Label
@onready var contract_list: VBoxContainer  = $ContractsPanel/VBox/ContractList
@onready var tutorial_label: Label         = $TutorialPanel/Label
@onready var stats_label: Label            = $StatsLabel
@onready var pause_menu: PanelContainer    = $PauseMenu
@onready var controls_panel: PanelContainer = $ControlsPanel

const WOOD_NAMES  = { 0: "Pino", 1: "Abedul", 2: "Roble", 3: "Secuoya" }
const ITEM_NAMES  = { "plank_0": "Tab.Pino", "plank_1": "Tab.Abedul",
                      "plank_2": "Tab.Roble", "plank_3": "Tab.Secuoya" }
const WOOD_PRICES = { 0: 6, 1: 8, 2: 10, 3: 25,
                      "plank_0": 9, "plank_1": 12, "plank_2": 15, "plank_3": 38 }

var _notif_queue: Array[String] = []
var _notif_busy := false
var _stats_visible := false

func _ready():
	add_to_group("hud")
	_connect_signals()
	_refresh_all()
	cutting_bar.visible    = false
	cutting_label.visible  = false
	sell_prompt.visible    = false
	notification_label.visible = false
	zone_label_node.visible    = false
	level_up_label.visible     = false
	rush_hour_label.visible    = false
	achievement_panel.visible  = false
	stats_label.visible        = false
	pause_menu.visible         = false
	controls_panel.visible     = false
	$PauseMenu/VBox/ResumeBtn.pressed.connect(func(): toggle_pause())
	$PauseMenu/VBox/MainMenuBtn.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	$PauseMenu/VBox/QuitBtn.pressed.connect(get_tree().quit)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_end"):  # Tab key
		_toggle_stats()
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_H:
		controls_panel.visible = not controls_panel.visible

func toggle_pause() -> void:
	var pausing := not pause_menu.visible
	pause_menu.visible = pausing
	get_tree().paused  = pausing
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if not pausing else Input.MOUSE_MODE_VISIBLE)

func _connect_signals():
	Inventory.inventory_changed.connect(_refresh_inventory)
	ProgressSystem.coins_changed.connect(_refresh_coins)
	ProgressSystem.upgrade_purchased.connect(_refresh_upgrades)
	ProgressSystem.cutting_xp_changed.connect(_refresh_skill)
	DailyContracts.contracts_changed.connect(_refresh_contracts)
	DailyContracts.contract_completed.connect(_on_contract_completed)
	Tutorial.tutorial_changed.connect(_on_tutorial_changed)
	AchievementSystem.achievement_unlocked.connect(func(_id, data): show_achievement(data))
	StatsTracker.stats_changed.connect(_refresh_stats)

	var zone_manager = get_tree().get_first_node_in_group("zone_manager")
	if zone_manager:
		zone_manager.zone_changed.connect(_on_zone_changed)

func _refresh_all():
	_refresh_inventory()
	_refresh_coins(ProgressSystem.coins)
	_refresh_upgrades("", 0)
	_refresh_skill(ProgressSystem.cutting_xp, ProgressSystem.cutting_level, ProgressSystem.get_xp_to_next_level())
	_refresh_contracts()
	_refresh_stats()
	var msg := ""
	var messages := [
		"1/4  [LMB] Corta un arbol.",
		"2/4  [E] Lleva los troncos al ASERRADERO.",
		"3/4  [F] Ve a la ZONA DE VENTA y vende.",
		"4/4  [E] Entra a la TIENDA y mejora tu hacha.",
	]
	if not Tutorial.completed and Tutorial.step < messages.size():
		msg = messages[Tutorial.step]
	_on_tutorial_changed(msg, not Tutorial.completed and msg != "")

func _refresh_coins(amount: int):
	coins_label.text = "Monedas: $%d" % amount

func _refresh_inventory():
	for child in inventory_list.get_children():
		child.queue_free()

	var total    = Inventory.total_items
	var capacity = ProgressSystem.get_inventory_capacity()
	capacity_label.text = "Carga: %d / %d" % [total, capacity]

	if Inventory.items.is_empty():
		var e = Label.new(); e.text = "  (vacio)"
		inventory_list.add_child(e)
		return

	for type in Inventory.items:
		var row    = Label.new()
		var iname  = ITEM_NAMES.get(type, WOOD_NAMES.get(type, "Madera"))
		var amount = Inventory.items[type]
		var price  = amount * WOOD_PRICES.get(type, 5)
		row.text   = "  %s x%d ($%d)" % [iname, amount, price]
		inventory_list.add_child(row)

func _refresh_upgrades(_type: String, _level: int):
	axe_label.text     = "Hacha: %s" % ProgressSystem.AXE_LEVELS[ProgressSystem.axe_level]["name"]
	vehicle_label.text = "Vehiculo: %s" % ProgressSystem.VEHICLE_LEVELS[ProgressSystem.vehicle_level]["name"]

func _refresh_skill(xp: int, level: int, xp_to_next: int):
	var bonus := roundi((ProgressSystem.get_cutting_speed_multiplier() - 1.0) * 100.0)
	skill_label.text = "LJ Lv.%d  %d/%d XP  (+%d%%)" % [level, xp, xp_to_next, bonus]

func _refresh_contracts():
	for child in contract_list.get_children():
		child.queue_free()
	for contract in DailyContracts.contracts:
		var row   := Label.new()
		var state := "DONE" if contract.completed else "%d/%d" % [contract.progress, contract.target]
		row.text   = "%s [%s] +$%d" % [contract.title, state, contract.reward]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if contract.completed:
			row.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
		contract_list.add_child(row)

func _refresh_stats():
	stats_label.text = StatsTracker.get_summary()

func _on_contract_completed(contract: Dictionary):
	queue_notification("CONTRATO: +$%d!" % contract.reward)

func _on_tutorial_changed(message: String, should_show: bool):
	tutorial_label.text = message
	$TutorialPanel.visible = should_show and message != ""

func _toggle_stats():
	_stats_visible = not _stats_visible
	stats_label.visible = _stats_visible

# ── CUTTING BAR ───────────────────────────────────────────────────────────────
func update_cutting_bar(progress: float, max_health: float, cutting: bool, wood_name: String = ""):
	cutting_bar.visible   = cutting
	cutting_label.visible = cutting
	if cutting and max_health > 0:
		cutting_bar.value = progress / max_health
		cutting_label.text = wood_name if wood_name != "" else ""

# ── SELL PROMPT ───────────────────────────────────────────────────────────────
func show_sell_prompt(show: bool, amount: int):
	sell_prompt.visible = show
	if show:
		sell_prompt_label.text = "[F] Vender — $%d" % amount

# ── NOTIFICATION QUEUE ────────────────────────────────────────────────────────
func show_sell_result(amount: int, custom_msg: String = ""):
	var msg := custom_msg if custom_msg != "" else "+$%d vendidos!" % amount
	queue_notification(msg)

func queue_notification(msg: String) -> void:
	_notif_queue.push_back(msg)
	if not _notif_busy:
		_pump_notifications()

func _pump_notifications() -> void:
	if _notif_queue.is_empty():
		_notif_busy = false
		return
	_notif_busy = true
	notification_label.text    = _notif_queue.pop_front()
	notification_label.visible = true
	notification_label.modulate.a = 1.0
	await get_tree().create_timer(1.8).timeout
	var tw := create_tween()
	tw.tween_property(notification_label, "modulate:a", 0.0, 0.5)
	await tw.finished
	notification_label.visible = false
	notification_label.modulate.a = 1.0
	_pump_notifications()

# ── TIME + WEATHER + RUSH ─────────────────────────────────────────────────────
func update_time(hour: int, minute: int):
	var period = "AM" if hour < 12 else "PM"
	var h = hour if hour <= 12 else hour - 12
	if h == 0: h = 12
	time_label.text = "%d:%02d %s" % [h, minute, period]

func update_weather(weather_text: String):
	weather_label.text = weather_text

func update_rush_hour(active: bool, mult: float, label_text: String):
	rush_hour_label.visible = active
	if active:
		rush_hour_label.text = "⚡ %s" % label_text

# ── STAMINA ───────────────────────────────────────────────────────────────────
func update_stamina(value: float, max_val: float):
	stamina_bar.value   = (value / max_val) * 100.0
	stamina_bar.visible = value < max_val

# ── LEVEL UP FLASH ────────────────────────────────────────────────────────────
func show_level_up(level: int):
	level_up_label.text      = "NIVEL %d DESBLOQUEADO!" % level
	level_up_label.visible   = true
	level_up_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(level_up_label, "modulate:a", 0.0, 1.0)
	await tw.finished
	level_up_label.visible = false
	level_up_label.modulate.a = 1.0

# ── ACHIEVEMENT POPUP ─────────────────────────────────────────────────────────
func show_achievement(data: Dictionary) -> void:
	achievement_label.text   = "%s %s\n%s" % [data.icon, data.title, data.desc]
	achievement_panel.visible = true
	achievement_panel.modulate.a = 1.0
	await get_tree().create_timer(3.0).timeout
	var tw := create_tween()
	tw.tween_property(achievement_panel, "modulate:a", 0.0, 0.8)
	await tw.finished
	achievement_panel.visible = false
	achievement_panel.modulate.a = 1.0

# ── ZONE LABEL ────────────────────────────────────────────────────────────────
func _on_zone_changed(zone_id: String, zone_label: String):
	if zone_id == "":
		zone_label_node.visible = false
		return
	zone_label_node.text    = zone_label
	zone_label_node.visible = true
	await get_tree().create_timer(3.0).timeout
	zone_label_node.visible = false
