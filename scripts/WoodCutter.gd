extends Node3D

@onready var raycast: RayCast3D = $RayCast3D

var is_cutting: bool = false
var cut_progress: float = 0.0
var cut_target: Node = null
var _swing_cooldown: float = 0.0
var _blocked_target: Node = null
var _camera: Camera3D = null

const BASE_SWING_INTERVAL := 0.42

func _ready():
	raycast.target_position = Vector3(0, 0, -3.0)
	await get_tree().process_frame
	_camera = get_tree().get_first_node_in_group("player_camera")

func _process(delta):
	_handle_cutting(delta)

func _handle_cutting(delta):
	_swing_cooldown = maxf(0.0, _swing_cooldown - delta)

	if Input.is_action_pressed("cut") and raycast.is_colliding():
		var target = raycast.get_collider()

		if not target.has_method("take_damage"):
			_reset_cutting()
			return

		if target.has_method("get_required_axe_level") and ProgressSystem.axe_level < target.get_required_axe_level():
			if _blocked_target != target:
				_blocked_target = target
				var hud = get_tree().get_first_node_in_group("hud")
				if hud:
					hud.queue_notification("%s requiere mejor hacha!" % target.get_wood_name())
			_reset_cutting()
			return
		_blocked_target = null

		if cut_target != target:
			_reset_cutting()
			cut_target = target
			if cut_target.has_method("on_cut_start"):
				cut_target.on_cut_start()
			if cut_target.get("is_giant"):
				var hud := get_tree().get_first_node_in_group("hud")
				if hud:
					hud.queue_notification("ARBOL GIGANTE! Mas troncos...")

		is_cutting = true
		if _swing_cooldown > 0.0:
			return

		var damage_per_second = ProgressSystem.get_axe_damage()
		var hardness = target.get_hardness() if target.has_method("get_hardness") else 1.0
		var effective_damage = (damage_per_second * BASE_SWING_INTERVAL) / hardness * WeatherSystem.cut_mod()
		_swing_cooldown = BASE_SWING_INTERVAL / ProgressSystem.get_cutting_speed_multiplier()

		cut_progress += effective_damage
		target.take_damage(effective_damage)
		ProgressSystem.add_cutting_xp(maxi(1, roundi(effective_damage * 0.25)))

		# Camera shake on each axe swing
		if _camera and _camera.has_method("shake"):
			_camera.shake(0.12, 0.04)

		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			var wname := target.get_wood_name() if target.has_method("get_wood_name") else ""
			var giant_tag := " [GIGANTE]" if target.get("is_giant") else ""
			hud.update_cutting_bar(cut_progress, target.max_health, true, wname + giant_tag)
	else:
		_reset_cutting()

func _reset_cutting():
	if is_cutting and cut_target and is_instance_valid(cut_target):
		if cut_target.has_method("on_cut_stop"):
			cut_target.on_cut_stop()

	is_cutting = false
	cut_progress = 0.0
	cut_target = null
	_swing_cooldown = 0.0

	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_cutting_bar(0, 1, false)
