extends Node

@onready var player: CharacterBody3D = get_parent()
@onready var dirt_audio: AudioStreamPlayer3D = $DirtAudio
@onready var path_audio: AudioStreamPlayer3D = $PathAudio

@export var dirt_sounds: Array[AudioStream] = []
@export var path_sounds: Array[AudioStream] = []

const STEP_INTERVAL_WALK := 0.45
const STEP_INTERVAL_PATH := 0.32

var _step_timer := 0.0
var _was_on_floor := false

func _ready() -> void:
	dirt_audio.max_distance = 18.0
	path_audio.max_distance = 18.0

func _process(delta: float) -> void:
	if not player.is_multiplayer_authority():
		return
	var on_floor := player.is_on_floor()
	var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if on_floor and horizontal_speed > 0.5:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_play_step()
			_step_timer = STEP_INTERVAL_PATH if player.on_path else STEP_INTERVAL_WALK
	if on_floor and not _was_on_floor:
		_play_land()
	_was_on_floor = on_floor

func _play_step() -> void:
	var sounds := path_sounds if player.on_path else dirt_sounds
	var audio := path_audio if player.on_path else dirt_audio
	if sounds.is_empty():
		return
	audio.stream = sounds[randi() % sounds.size()]
	audio.pitch_scale = randf_range(0.92, 1.08)
	audio.volume_db = -10.0
	audio.play()

func _play_land() -> void:
	if dirt_sounds.is_empty():
		return
	dirt_audio.stream = dirt_sounds[randi() % dirt_sounds.size()]
	dirt_audio.pitch_scale = 0.82
	dirt_audio.volume_db = -7.0
	dirt_audio.play()
