extends Node3D

const MANNEQUIN = "res://assets/characters/kaykit_animations/KayKit_Character_Animations_1.1/Mannequin Character/characters/Mannequin_Medium.glb"

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

	if data["wander"]:
		_add_walk_animation(model, root, data["pos"])
	else:
		_add_idle_animation(model)

func _add_idle_animation(model: Node3D):
	# Gentle breathing bob
	var tween = create_tween().set_loops()
	tween.tween_property(model, "position", Vector3(0, 0.04, 0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(model, "position", Vector3(0, 0.0,  0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Slow head-look side to side (rotation on Y)
	var tween2 = create_tween().set_loops()
	tween2.tween_property(model, "rotation", Vector3(0,  0.3, 0), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween2.tween_property(model, "rotation", Vector3(0, -0.3, 0), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween2.tween_property(model, "rotation", Vector3(0,  0.0, 0), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _add_walk_animation(model: Node3D, root: Node3D, origin: Vector3):
	# Walking bob: bounces while moving
	var bob = create_tween().set_loops()
	bob.tween_property(model, "position", Vector3(0, 0.08, 0), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(model, "position", Vector3(0, 0.0,  0), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Body lean forward while walking
	model.rotation.x = -0.12

	# Wander movement
	var wander = create_tween().set_loops()
	var a = origin + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
	var b = origin + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))

	wander.tween_method(_face_toward.bind(root, a), 0.0, 1.0, 0.2)
	wander.tween_property(root, "global_position", a, randf_range(3.5, 5.0)).set_trans(Tween.TRANS_SINE)
	wander.tween_method(_face_toward.bind(root, b), 0.0, 1.0, 0.2)
	wander.tween_property(root, "global_position", b, randf_range(3.5, 5.0)).set_trans(Tween.TRANS_SINE)
	wander.tween_method(_face_toward.bind(root, origin), 0.0, 1.0, 0.2)
	wander.tween_property(root, "global_position", origin, randf_range(3.5, 5.0)).set_trans(Tween.TRANS_SINE)

func _face_toward(_t: float, npc: Node3D, target: Vector3):
	var dir = (target - npc.global_position)
	dir.y = 0.0
	if dir.length() > 0.1:
		npc.rotation.y = atan2(dir.x, dir.z)
