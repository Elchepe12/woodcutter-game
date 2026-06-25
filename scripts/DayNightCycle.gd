extends DirectionalLight3D

@export var day_duration: float = 300.0
@export var start_hour: float = 8.0

const SKY_COLORS = {
	"dawn":    Color(0.95, 0.60, 0.40, 1),
	"morning": Color(0.55, 0.75, 1.00, 1),
	"noon":    Color(0.40, 0.65, 1.00, 1),
	"evening": Color(0.95, 0.55, 0.25, 1),
	"night":   Color(0.05, 0.05, 0.15, 1),
}

# Rush hours: { hour_start: { end, multiplier } }
const RUSH_HOURS = [
	{ "start": 10, "end": 12, "mult": 1.4, "label": "HORA PUNTA MANANA x1.4" },
	{ "start": 17, "end": 19, "mult": 1.6, "label": "HORA PUNTA TARDE x1.6" },
]

var time_of_day: float = 0.0
var world_env: WorldEnvironment = null
var _last_rush_active: bool = false
var _day_count: int = 1

signal rush_hour_changed(active: bool, multiplier: float, label: String)
signal new_day(day_number: int)

func _ready():
	add_to_group("day_night_cycle")
	time_of_day = start_hour / 24.0
	world_env = get_parent().get_node_or_null("WorldEnvironment")

func _process(delta):
	time_of_day += delta / day_duration
	if time_of_day >= 1.0:
		time_of_day = 0.0
		_day_count += 1
		new_day.emit(_day_count)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.queue_notification("Dia %d comienza!" % _day_count)

	_update_sun()
	_update_sky()
	_update_hud()
	_check_rush_hour()

func _update_sun():
	var angle = time_of_day * TAU - PI * 0.5
	rotation_degrees.x = rad_to_deg(angle)
	rotation_degrees.y = -30.0

	var hour = get_hour()
	if hour >= 6 and hour < 8:
		light_energy = lerpf(0.0, 0.5, (hour - 6.0) / 2.0)
	elif hour >= 8 and hour < 18:
		light_energy = lerpf(0.5, 1.2, (hour - 8.0) / 10.0) if hour < 13 else lerpf(1.2, 0.5, (hour - 13.0) / 5.0)
	elif hour >= 18 and hour < 20:
		light_energy = lerpf(0.5, 0.0, (hour - 18.0) / 2.0)
	else:
		light_energy = 0.0

func _update_sky():
	if not world_env or not world_env.environment:
		return
	var hour = get_hour_float()
	var sky_color: Color

	if hour < 6.0:
		sky_color = SKY_COLORS["night"]
	elif hour < 8.0:
		sky_color = SKY_COLORS["night"].lerp(SKY_COLORS["dawn"], (hour - 6.0) / 2.0)
	elif hour < 10.0:
		sky_color = SKY_COLORS["dawn"].lerp(SKY_COLORS["morning"], (hour - 8.0) / 2.0)
	elif hour < 17.0:
		sky_color = SKY_COLORS["morning"].lerp(SKY_COLORS["noon"], (hour - 10.0) / 7.0)
	elif hour < 19.0:
		sky_color = SKY_COLORS["noon"].lerp(SKY_COLORS["evening"], (hour - 17.0) / 2.0)
	elif hour < 21.0:
		sky_color = SKY_COLORS["evening"].lerp(SKY_COLORS["night"], (hour - 19.0) / 2.0)
	else:
		sky_color = SKY_COLORS["night"]

	world_env.environment.ambient_light_color  = sky_color
	world_env.environment.background_color    = sky_color
	# Keep ambient energy higher at night so player can see
	var h := get_hour_float()
	if h < 6.0 or h >= 21.0:
		world_env.environment.ambient_light_energy = 0.55
	else:
		world_env.environment.ambient_light_energy = 0.35
	if world_env.environment.sky and world_env.environment.sky.sky_material is ProceduralSkyMaterial:
		var sky_mat: ProceduralSkyMaterial = world_env.environment.sky.sky_material
		sky_mat.sky_horizon_color    = sky_color
		sky_mat.sky_top_color        = sky_color.darkened(0.38)
		sky_mat.ground_horizon_color = sky_color.darkened(0.62)

func _update_hud():
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_time"):
		hud.update_time(get_hour(), get_minute())

func _check_rush_hour():
	var h := get_hour()
	var rush = _get_rush_hour_data(h)
	var active := rush != null
	if active != _last_rush_active:
		_last_rush_active = active
		var mult: float = rush.mult if rush else 1.0
		var lbl: String = rush.label if rush else ""
		rush_hour_changed.emit(active, mult, lbl)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("update_rush_hour"):
			hud.update_rush_hour(active, mult, lbl)

func _get_rush_hour_data(hour: int):
	for r in RUSH_HOURS:
		if hour >= r.start and hour < r.end:
			return r
	return null

func get_price_multiplier() -> float:
	var r = _get_rush_hour_data(get_hour())
	return r.mult if r else 1.0

func get_hour() -> int:
	return int(time_of_day * 24.0) % 24

func get_minute() -> int:
	return int((time_of_day * 24.0 - get_hour()) * 60.0)

func get_hour_float() -> float:
	return time_of_day * 24.0
