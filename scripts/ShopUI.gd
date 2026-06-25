extends CanvasLayer

@onready var main_panel: PanelContainer        = $MainPanel
@onready var coins_display: Label              = $MainPanel/VBoxContainer/CoinsDisplay
@onready var skill_display: Label              = $MainPanel/VBoxContainer/SkillDisplay
@onready var axes_container: VBoxContainer     = $MainPanel/VBoxContainer/TabContainer/Hachas
@onready var vehicles_container: VBoxContainer = $MainPanel/VBoxContainer/TabContainer/Vehículos
@onready var close_btn: Button                 = $MainPanel/VBoxContainer/CloseBtn

func _ready():
	close_btn.pressed.connect(close)
	ProgressSystem.coins_changed.connect(_refresh_coins)
	ProgressSystem.cutting_xp_changed.connect(func(_x, _l, _n): _refresh_skill())
	visible = false

func open():
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_all()

func close():
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _refresh_all():
	_refresh_coins(ProgressSystem.coins)
	_refresh_skill()
	_build_axe_rows()
	_build_vehicle_rows()

func _refresh_coins(amount: int):
	coins_display.text = "Monedas: $%d" % amount

func _refresh_skill():
	var lv  := ProgressSystem.cutting_level
	var xp  := ProgressSystem.cutting_xp
	var nxt := ProgressSystem.get_xp_to_next_level()
	var spd := int((ProgressSystem.get_cutting_speed_multiplier() - 1.0) * 100.0)
	skill_display.text = "Lumberjack Lv.%d  (%d/%d XP)  Velocidad +%d%%" % [lv, xp, nxt, spd]

func _build_axe_rows():
	for child in axes_container.get_children():
		child.queue_free()
	var current = ProgressSystem.axe_level
	for i in ProgressSystem.AXE_LEVELS.size():
		var data = ProgressSystem.AXE_LEVELS[i]
		var row = _make_row(
			data["name"],
			"Dano: %.0f/s" % data["damage"],
			data["upgrade_cost"], i, current,
			func(): _buy_axe()
		)
		axes_container.add_child(row)

func _buy_axe():
	if ProgressSystem.upgrade_axe():
		_refresh_all()

func _build_vehicle_rows():
	for child in vehicles_container.get_children():
		child.queue_free()
	var current = ProgressSystem.vehicle_level
	for i in ProgressSystem.VEHICLE_LEVELS.size():
		var data = ProgressSystem.VEHICLE_LEVELS[i]
		var cap = 50 + data["capacity_bonus"]
		var row = _make_row(
			data["name"],
			"Capacidad: %d unidades" % cap,
			data["upgrade_cost"], i, current,
			func(): _buy_vehicle()
		)
		vehicles_container.add_child(row)

func _buy_vehicle():
	if ProgressSystem.upgrade_vehicle():
		_refresh_all()

func _make_row(item_name: String, stat_text: String, cost: int,
		level_index: int, current_level: int, on_buy: Callable) -> HBoxContainer:

	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 48)

	var status = Label.new()
	status.custom_minimum_size = Vector2(28, 0)
	if level_index < current_level:
		status.text = "v"
		status.add_theme_color_override("font_color", Color.GREEN)
	elif level_index == current_level:
		status.text = ">"
		status.add_theme_color_override("font_color", Color.YELLOW)
	else:
		status.text = " "
	row.add_child(status)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label = Label.new()
	name_label.text = item_name
	var stat_label = Label.new()
	stat_label.text = stat_text
	stat_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.add_child(name_label)
	info.add_child(stat_label)
	row.add_child(info)

	if level_index == 0:
		var lbl = Label.new()
		lbl.text = "Base"
		lbl.add_theme_color_override("font_color", Color.GRAY)
		row.add_child(lbl)
	elif level_index <= current_level:
		var lbl = Label.new()
		lbl.text = "Comprado"
		lbl.add_theme_color_override("font_color", Color.GREEN)
		row.add_child(lbl)
	elif level_index == current_level + 1:
		var btn = Button.new()
		btn.text = "$%d" % cost
		btn.disabled = ProgressSystem.coins < cost
		btn.pressed.connect(on_buy)
		if ProgressSystem.coins < cost:
			btn.add_theme_color_override("font_color", Color.RED)
		row.add_child(btn)
	else:
		var lbl = Label.new()
		lbl.text = "Bloqueado"
		lbl.add_theme_color_override("font_color", Color.GRAY)
		row.add_child(lbl)

	return row
