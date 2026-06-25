extends Node

const SAVE_PATH := "user://achievements.cfg"

const ALL = {
	"primer_arbol":  { "title": "Primer golpe",       "desc": "Corta tu primer arbol",          "icon": "🌲" },
	"primer_venta":  { "title": "Primer negocio",      "desc": "Vende madera por primera vez",   "icon": "💰" },
	"acumulador":    { "title": "Acumulador",          "desc": "Llena el inventario al 100%",    "icon": "📦" },
	"rico":          { "title": "Rico",                "desc": "Gana 500 monedas en total",      "icon": "🤑" },
	"hachero":       { "title": "Hachero",             "desc": "Corta 10 arboles",               "icon": "🪓" },
	"primer_upgrade":{ "title": "Primera mejora",      "desc": "Compra tu primera mejora",       "icon": "⬆" },
	"hora_punta":    { "title": "Oportunista",         "desc": "Vende durante la Hora Punta",    "icon": "⚡" },
	"lv5":           { "title": "Lumberjack Pro",      "desc": "Alcanza Lumberjack nivel 5",     "icon": "⭐" },
	"aserrador":     { "title": "Aserrador",           "desc": "Procesa 20 troncos en el aserradero", "icon": "⚙" },
	"nocturno":      { "title": "Trabajador nocturno", "desc": "Vende despues de las 10 PM",     "icon": "🌙" },
	"tablones":      { "title": "Carpintero",          "desc": "Procesa tus primeros troncos",   "icon": "🪵" },
	"contratos":     { "title": "Contratista",         "desc": "Completa 3 contratos diarios",   "icon": "📋" },
	"gigante":       { "title": "David vs Goliat",     "desc": "Tala un arbol gigante",          "icon": "🌳" },
}

var unlocked: Dictionary = {}

signal achievement_unlocked(id: String, data: Dictionary)

func _ready() -> void:
	_load()

func unlock(id: String) -> void:
	if id in unlocked or id not in ALL:
		return
	unlocked[id] = true
	_save()
	var data = ALL[id].duplicate()
	achievement_unlocked.emit(id, data)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_achievement"):
		hud.show_achievement(data)

func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false)

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("achievements", "unlocked", unlocked)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var v = cfg.get_value("achievements", "unlocked", {})
	if v is Dictionary:
		unlocked = v
