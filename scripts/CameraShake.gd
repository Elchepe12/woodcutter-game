extends Camera3D

const FOV_NORMAL: float  = 75.0
const FOV_SPRINT: float  = 85.0
const FOV_SPEED: float   = 8.0

var shake_intensity: float = 0.0
var shake_duration: float  = 0.0
var _elapsed: float        = 0.0
var _origin: Vector3
var _target_fov: float     = FOV_NORMAL

func _ready():
	add_to_group("player_camera")
	_origin = position
	fov = FOV_NORMAL

func shake(duration: float, intensity: float):
	shake_duration = duration
	shake_intensity = intensity
	_elapsed = 0.0

func set_sprinting(sprinting: bool):
	_target_fov = FOV_SPRINT if sprinting else FOV_NORMAL

func _process(delta):
	# FOV lerp for sprint feel
	fov = lerpf(fov, _target_fov, delta * FOV_SPEED)

	# Position shake
	if _elapsed < shake_duration:
		_elapsed += delta
		var t = 1.0 - (_elapsed / shake_duration)
		position = _origin + Vector3(
			randf_range(-1, 1) * shake_intensity * t,
			randf_range(-1, 1) * shake_intensity * t,
			0
		)
	else:
		position = _origin
