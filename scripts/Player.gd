extends CharacterBody3D

const MOUSE_SENSITIVITY   = 0.002
const JUMP_VELOCITY       = 4.5
const SPEED_NORMAL: float = 5.0
const SPEED_ON_PATH: float = 7.5
const SPEED_SPRINT: float  = 9.5
const MAX_STAMINA: float   = 100.0
const STAMINA_DRAIN: float = 28.0
const STAMINA_REGEN: float = 20.0

var SPEED: float = SPEED_NORMAL
var on_path: bool = false
var is_sprinting: bool = false
var stamina: float = MAX_STAMINA
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

const PLAYER_COLORS = [
	Color(0.2, 0.5, 1.0),
	Color(1.0, 0.3, 0.3),
	Color(0.3, 0.9, 0.3),
	Color(1.0, 0.8, 0.1),
]

@onready var head: Node3D           = $Head
@onready var camera: Camera3D       = $Head/Camera3D
@onready var headlamp: OmniLight3D  = $Head/Camera3D/Headlamp
@onready var body_mesh: Node3D      = $Body

var _headlamp_on: bool = false

var _sync_pos: Vector3 = Vector3.ZERO
var _sync_rot: Vector3 = Vector3.ZERO
var _sync_head: float  = 0.0

func _ready():
	add_to_group("player")
	_setup_character()
	ProgressSystem.level_up.connect(_on_level_up)

func _setup_character():
	var color_idx = (NetworkManager.my_id() - 1) % PLAYER_COLORS.size()
	_set_body_color(PLAYER_COLORS[color_idx])

	if is_multiplayer_authority():
		camera.current = true
		body_mesh.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		camera.current = false
		body_mesh.visible = true
		set_physics_process(false)

func _set_body_color(color: Color):
	for child in body_mesh.get_children():
		if child is MeshInstance3D:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = color
			child.material_override = mat

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	if event.is_action_pressed("toggle_light"):
		_headlamp_on = not _headlamp_on
		headlamp.light_energy = 4.0 if _headlamp_on else 0.0
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.queue_notification("Linterna: %s [L]" % ("ON" if _headlamp_on else "OFF"))

func _physics_process(delta):
	if not is_multiplayer_authority():
		_smooth_remote(delta)
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	_handle_stamina(delta)

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = SPEED

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	if is_on_floor() and velocity.length() > 0.5:
		StatsTracker.add_distance(velocity.length() * delta)

	if multiplayer.has_multiplayer_peer() and Engine.get_physics_frames() % 3 == 0:
		_rpc_sync_state.rpc(global_position, rotation, head.rotation.x)

func _handle_stamina(delta: float) -> void:
	var want_sprint = Input.is_action_pressed("sprint") and velocity.length() > 0.5 and is_on_floor()

	var weather_speed := WeatherSystem.speed_mod()
	if want_sprint and stamina > 0.0:
		is_sprinting = true
		stamina = maxf(0.0, stamina - STAMINA_DRAIN * delta)
		SPEED = (SPEED_SPRINT if not on_path else SPEED_ON_PATH * 1.25) * weather_speed
	else:
		is_sprinting = false
		stamina = minf(MAX_STAMINA, stamina + STAMINA_REGEN * delta)
		SPEED = (SPEED_ON_PATH if on_path else SPEED_NORMAL) * weather_speed

	if camera.has_method("set_sprinting"):
		camera.set_sprinting(is_sprinting)

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_stamina"):
		hud.update_stamina(stamina, MAX_STAMINA)

func _on_level_up(new_level: int) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_level_up"):
		hud.show_level_up(new_level)

@rpc("unreliable")
func _rpc_sync_state(pos: Vector3, rot: Vector3, head_x: float):
	_sync_pos  = pos
	_sync_rot  = rot
	_sync_head = head_x

func _smooth_remote(delta):
	global_position = global_position.lerp(_sync_pos, delta * 15.0)
	rotation        = rotation.lerp(_sync_rot, delta * 15.0)
	head.rotation.x = lerp(head.rotation.x, _sync_head, delta * 15.0)

func set_player_name(player_name: String):
	if has_node("Body/NameLabel"):
		$Body/NameLabel.text = player_name

func set_on_path(value: bool):
	on_path = value
