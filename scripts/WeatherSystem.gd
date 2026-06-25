extends Node

enum Weather { SUNNY, CLOUDY, RAINY, FOGGY }

const WEATHER_NAMES = {
	Weather.SUNNY:  "Soleado",
	Weather.CLOUDY: "Nublado",
	Weather.RAINY:  "Lluvia",
	Weather.FOGGY:  "Niebla",
}
const WEATHER_ICONS = {
	Weather.SUNNY:  "☀",
	Weather.CLOUDY: "☁",
	Weather.RAINY:  "🌧",
	Weather.FOGGY:  "🌫",
}
const WEATHER_WEIGHTS = [0.42, 0.28, 0.18, 0.12]
const WEATHER_MODS = {
	Weather.SUNNY:  { "speed": 1.00, "cut": 1.00, "fog": 0.004, "ambient": 1.0  },
	Weather.CLOUDY: { "speed": 1.00, "cut": 0.95, "fog": 0.010, "ambient": 0.80 },
	Weather.RAINY:  { "speed": 0.85, "cut": 0.78, "fog": 0.022, "ambient": 0.60 },
	Weather.FOGGY:  { "speed": 0.90, "cut": 0.88, "fog": 0.038, "ambient": 0.55 },
}

var current: Weather = Weather.SUNNY
var _timer: float = 0.0

signal weather_changed(weather: Weather, name: String)

func _ready() -> void:
	_apply(Weather.SUNNY)
	_timer = randf_range(50.0, 140.0)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_pick_new_weather()

func _pick_new_weather() -> void:
	var roll := randf()
	var acc  := 0.0
	var next := Weather.SUNNY
	for i in WEATHER_WEIGHTS.size():
		acc += WEATHER_WEIGHTS[i]
		if roll < acc:
			next = i as Weather
			break
	_timer = randf_range(50.0, 140.0)
	_apply(next)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.queue_notification("Clima cambia: %s %s" % [WEATHER_ICONS[next], WEATHER_NAMES[next]])

func _apply(w: Weather) -> void:
	current = w
	var mods = WEATHER_MODS[w]

	# Update fog in WorldEnvironment
	var env := get_tree().get_first_node_in_group("world_environment")
	if env and env.environment:
		env.environment.fog_density = mods.fog

	# Tell HUD
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_weather"):
		hud.update_weather(WEATHER_ICONS[w] + " " + WEATHER_NAMES[w])

	weather_changed.emit(w, WEATHER_NAMES[w])

func speed_mod() -> float:
	return WEATHER_MODS[current]["speed"]

func cut_mod() -> float:
	return WEATHER_MODS[current]["cut"]
