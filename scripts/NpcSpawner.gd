extends Node3D

const CHAR_BASE = "res://assets/characters/kenney_mini_characters/Models/GLB format/"

const MALE_MODELS   = ["character-male-a.glb","character-male-b.glb","character-male-c.glb",
					    "character-male-d.glb","character-male-e.glb","character-male-f.glb"]
const FEMALE_MODELS = ["character-female-a.glb","character-female-b.glb","character-female-c.glb"]

const NPC_DATA = [
	{ "name": "Mercader",    "pos": Vector3(2.5, 0, 3.5),   "rot": PI,       "model": "character-male-b.glb",   "wander": false },
	{ "name": "Trabajador",  "pos": Vector3(-10, 0, 2),     "rot": PI * 0.5, "model": "character-male-d.glb",   "wander": false },
	{ "name": "Aldeano",     "pos": Vector3(4, 0, 8),       "rot": 0.0,      "model": "character-female-a.glb", "wander": true  },
	{ "name": "Aldeana",     "pos": Vector3(-2, 0, 10),     "rot": PI * 1.5, "model": "character-female-c.glb", "wander": true  },
]

func _ready():
	call_deferred("_spawn_npcs")

func _spawn_npcs():
	for data in NPC_DATA:
		_create_npc(data)

func _create_npc(data: Dictionary):
	var packed = load(CHAR_BASE + data["model"])
	if not packed:
		return

	var root = Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = data["pos"]
	root.rotation.y = data["rot"]

	var model = packed.instantiate()
	model.scale = Vector3.ONE * 1.2
	root.add_child(model)

	var label = Label3D.new()
	label.text = data["name"]
	label.font_size = 18
	label.position = Vector3(0, 2.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.92, 0.6)
	label.outline_modulate = Color(0, 0, 0, 1)
	label.outline_render_mode = Label3D.OUTLINE_RENDER_MODE_GLYPH
	root.add_child(label)

	if data["wander"]:
		_add_wander(root, data["pos"])

func _add_wander(npc: Node3D, origin: Vector3):
	var tween = create_tween()
	tween.set_loops()
	var a = origin + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5))
	var b = origin + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5))
	tween.tween_property(npc, "global_position", a, randf_range(3.0, 5.0)).set_trans(Tween.TRANS_SINE)
	tween.tween_property(npc, "global_position", b, randf_range(3.0, 5.0)).set_trans(Tween.TRANS_SINE)
	tween.tween_property(npc, "global_position", origin, randf_range(3.0, 5.0)).set_trans(Tween.TRANS_SINE)
