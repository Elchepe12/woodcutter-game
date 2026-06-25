extends Control

@onready var btn_solo: Button      = $VBox/BtnSolo
@onready var btn_continue: Button  = $VBox/BtnContinue
@onready var btn_new_game: Button  = $VBox/BtnNewGame
@onready var btn_host: Button      = $VBox/BtnHost
@onready var btn_join: Button      = $VBox/BtnJoin
@onready var ip_input: LineEdit    = $VBox/IPInput
@onready var status_label: Label   = $VBox/StatusLabel

func _ready():
	btn_solo.pressed.connect(_on_continue)
	btn_continue.pressed.connect(_on_continue)
	btn_new_game.pressed.connect(_on_new_game)
	btn_host.pressed.connect(_on_host)
	btn_join.pressed.connect(_on_join)

	NetworkManager.connected_to_host.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	ip_input.text = "127.0.0.1"

	var cfg := ConfigFile.new()
	var has_save := cfg.load("user://player_progress.cfg") == OK
	btn_continue.disabled = not has_save
	btn_continue.visible  = has_save
	btn_solo.visible      = not has_save

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_new_game() -> void:
	for path in [
		"user://player_progress.cfg", "user://daily_contracts.cfg",
		"user://tutorial_state.cfg", "user://achievements.cfg",
		"user://stats.cfg", "user://player_inventory.cfg",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_host():
	NetworkManager.host()
	status_label.text = "Servidor iniciado. IP: %s" % _get_local_ip()
	btn_host.disabled = true
	btn_join.disabled = true
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_join():
	var ip := ip_input.text.strip_edges()
	if ip.is_empty():
		status_label.text = "Escribe una IP primero"
		return
	status_label.text = "Conectando a %s..." % ip
	btn_join.disabled = true
	btn_host.disabled = true
	NetworkManager.join(ip)

func _on_connected():
	status_label.text = "Conectado!"
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_connection_failed():
	status_label.text = "Error: no se pudo conectar"
	btn_join.disabled = false
	btn_host.disabled = false

func _get_local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.") or addr.begins_with("10."):
			return addr
	return "desconocida"
