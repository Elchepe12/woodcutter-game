extends Node3D

const MANNEQUIN = "res://assets/characters/kaykit_animations/KayKit_Character_Animations_1.1/Mannequin Character/characters/Mannequin_Medium.glb"
const ANIM_GENERAL  = "res://assets/characters/kaykit_animations/KayKit_Character_Animations_1.1/Animations/gltf/Rig_Medium/Rig_Medium_General.glb"
const ANIM_MOVEMENT = "res://assets/characters/kaykit_animations/KayKit_Character_Animations_1.1/Animations/gltf/Rig_Medium/Rig_Medium_MovementBasic.glb"

const NPC_DATA = [
	{ "name": "Mercader",   "pos": Vector3(2.5, 0, 3.5),  "rot": PI,       "wander": false },
	{ "name": "Trabajador", "pos": Vector3(-10, 0, 2),    "rot": PI * 0.5, "wander": false },
	{ "name": "Aldeano",    "pos": Vector3(4, 0, 8),      "rot": 0.0,      "wander": true  },
	{ "name": "Aldeana",    "pos": Vector3(-2, 0, 10),    "rot": PI * 1.5, "wander": true  },
]

func _ready():
	call_deferred("_spawn_npcs")

func _spawn_npcs():
	for data in NPC_DATA:
		_create_npc(data)

func _create_npc(data: Dictionary):
	var packed = load(MANNEQUIN)
	if not packed:
		return

	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = data["pos"]
	root.rotation.y = data["rot"]

	var model: Node3D = packed.instantiate()
	model.scale = Vector3.ONE * 0.9
	root.add_child(model)

	var label = Label3D.new()
	label.text = data["name"]
	label.font_size = 18
	label.position = Vector3(0, 2.4, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.92, 0.6)
	label.outline_modulate = Color(0, 0, 0, 1)
	root.add_child(label)

	# Load animation library from external GLB
	var anim_source = ANIM_MOVEMENT if data["wander"] else ANIM_GENERAL
	var anim_packed = load(anim_source)
	if not anim_packed:
		return

	var anim_node: Node = anim_packed.instantiate()
	var anim_player: AnimationPlayer = null

	# Find AnimationPlayer in mannequin model
	for child in model.get_children():
		if child is AnimationPlayer:
			anim_player = child
			break
		for sub in child.get_children():
			if sub is AnimationPlayer:
				anim_player = sub
				break

	if not anim_player:
		anim_node.queue_free()
		return

	# Find AnimationPlayer in animation source and copy library
	var src_player: AnimationPlayer = null
	for child in anim_node.get_children():
		if child is AnimationPlayer:
			src_player = child
			break
		for sub in child.get_children():
			if sub is AnimationPlayer:
				src_player = sub
				break

	if src_player:
		for lib_name in src_player.get_animation_library_list():
			var lib = src_player.get_animation_library(lib_name)
			if not anim_player.has_animation_library(lib_name):
				anim_player.add_animation_library(lib_name, lib)

		# Play idle or walk animation
		var target_anim = "Walk" if data["wander"] else "Idle"
		for lib_name in anim_player.get_animation_library_list():
			var lib = anim_player.get_animation_library(lib_name)
			for anim_name in lib.get_animation_list():
				if anim_name.to_lower().contains(target_anim.to_lower()):
					anim_player.play(lib_name + "/" + anim_name)
					break

	anim_node.queue_free()

	if data["wander"]:
		_add_wander(root, data["pos"])

func _add_wander(npc: Node3D, origin: Vector3):
	var tween = create_tween()
	tween.set_loops()
	var a = origin + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
	var b = origin + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
	tween.tween_property(npc, "global_position", a, randf_range(4.0, 6.0)).set_trans(Tween.TRANS_SINE)
	tween.tween_property(npc, "global_position", b, randf_range(4.0, 6.0)).set_trans(Tween.TRANS_SINE)
	tween.tween_property(npc, "global_position", origin, randf_range(4.0, 6.0)).set_trans(Tween.TRANS_SINE)
