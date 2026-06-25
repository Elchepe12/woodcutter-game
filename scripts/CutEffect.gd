# CutEffect.gd — adjunta como hijo del árbol (Wood)
extends Node

@onready var chip_particles: GPUParticles3D  = $ChipParticles
@onready var fall_particles: GPUParticles3D  = $FallParticles
@onready var cut_sound: AudioStreamPlayer3D  = $CutSound
@onready var fall_sound: AudioStreamPlayer3D = $FallSound

func _ready():
	_setup_chip_particles()
	_setup_fall_particles()
	_setup_audio()

func _setup_chip_particles():
	chip_particles.emitting = false
	chip_particles.one_shot = false
	chip_particles.amount = 12
	chip_particles.lifetime = 0.6
	chip_particles.explosiveness = 0.3

	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, -9.8, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.15
	mat.color = Color(0.55, 0.35, 0.15)
	chip_particles.process_material = mat

	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.08, 0.04, 0.08)
	chip_particles.draw_pass_1 = mesh

func _setup_fall_particles():
	fall_particles.emitting = false
	fall_particles.one_shot = true
	fall_particles.amount = 40
	fall_particles.lifetime = 1.2
	fall_particles.explosiveness = 0.9

	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, -9.8, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.2
	mat.color = Color(0.45, 0.28, 0.10)
	fall_particles.process_material = mat

	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.1, 0.05, 0.1)
	fall_particles.draw_pass_1 = mesh

func _setup_audio():
	cut_sound.max_distance = 20.0
	cut_sound.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	fall_sound.max_distance = 40.0
	fall_sound.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC

func start_cutting():
	chip_particles.emitting = true
	if not cut_sound.playing:
		cut_sound.play()

func stop_cutting():
	chip_particles.emitting = false
	cut_sound.stop()

func play_fall():
	chip_particles.emitting = false
	fall_particles.emitting = true
	cut_sound.stop()
	fall_sound.play()
	var camera = get_tree().get_first_node_in_group("player_camera")
	if camera and camera.has_method("shake"):
		camera.shake(0.3, 0.15)
