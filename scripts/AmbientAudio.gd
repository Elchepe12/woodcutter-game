extends Node

# Generates procedural ambient wind sound using AudioStreamGenerator
# Replace with real .ogg files for better quality

var _wind_player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _phase: float = 0.0
var _time: float = 0.0
var _wind_intensity: float = 0.3

const SAMPLE_RATE := 22050
const BUFFER_SIZE := 512

func _ready() -> void:
	_wind_player = AudioStreamPlayer.new()
	_wind_player.volume_db = -18.0
	_wind_player.bus = "Master"
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = 0.1
	_wind_player.stream = gen
	add_child(_wind_player)
	_wind_player.play()
	_playback = _wind_player.get_stream_playback()

func _process(delta: float) -> void:
	_time += delta
	# Slowly vary wind intensity
	_wind_intensity = 0.2 + sin(_time * 0.15) * 0.1 + sin(_time * 0.37) * 0.08

	if not _playback:
		return
	var frames := _playback.get_frames_available()
	for _i in frames:
		_phase += TAU * 80.0 / SAMPLE_RATE
		# White noise filtered to low frequencies (simple wind approximation)
		var noise := randf_range(-1.0, 1.0)
		var wind  := sin(_phase * 0.01) * _wind_intensity
		var sample := (noise * 0.12 + wind) * _wind_intensity
		_playback.push_frame(Vector2(sample, sample))
