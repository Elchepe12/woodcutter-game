extends SubViewportContainer

@onready var minimap_cam: Camera3D = $SubViewport/MinimapCamera
@onready var player_dot: ColorRect = $PlayerDot
@onready var north_label: Label    = $NorthLabel

const CAM_HEIGHT := 70.0
const CAM_SIZE   := 120.0
const MAP_PX     := 180.0

# Zone centers in world units and their colors
const ZONE_DATA = [
	{ "pos": Vector2(-20, -20), "color": Color(0.3, 0.8, 0.3),  "label": "P" },
	{ "pos": Vector2(20,  -20), "color": Color(0.4, 0.65, 0.2), "label": "R" },
	{ "pos": Vector2(-20, 20),  "color": Color(0.7, 0.85, 0.5), "label": "A" },
	{ "pos": Vector2(20,  20),  "color": Color(0.7, 0.3, 0.15), "label": "S" },
]

var _player: Node3D = null
var _zone_dots: Array = []

func _ready():
	custom_minimum_size = Vector2(MAP_PX, MAP_PX)
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	position = Vector2(-MAP_PX - 10, -MAP_PX - 10)

	minimap_cam.projection         = Camera3D.PROJECTION_ORTHOGONAL
	minimap_cam.size               = CAM_SIZE
	minimap_cam.rotation_degrees   = Vector3(-90.0, 0.0, 0.0)
	minimap_cam.near               = 0.1
	minimap_cam.far                = CAM_HEIGHT + 10.0
	minimap_cam.global_position    = Vector3(0.0, CAM_HEIGHT, 0.0)

	player_dot.color = Color(1.0, 0.18, 0.12)
	player_dot.size  = Vector2(8.0, 8.0)

	north_label.text = "N"

	_create_zone_dots()

	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player")

func _create_zone_dots():
	for zone in ZONE_DATA:
		var dot := ColorRect.new()
		dot.size  = Vector2(10, 10)
		dot.color = zone.color
		var pos2d := _world_to_map(zone.pos)
		dot.position = pos2d - Vector2(5, 5)
		add_child(dot)
		_zone_dots.append(dot)

		var lbl := Label.new()
		lbl.text = zone.label
		lbl.position = pos2d - Vector2(5, 14)
		lbl.add_theme_font_size_override("font_size", 9)
		add_child(lbl)

func _world_to_map(world_xz: Vector2) -> Vector2:
	var half := CAM_SIZE * 0.5
	var map_x := (world_xz.x / half) * (MAP_PX * 0.5) + MAP_PX * 0.5
	var map_y := (-world_xz.y / half) * (MAP_PX * 0.5) + MAP_PX * 0.5
	return Vector2(map_x, map_y)

func _process(_delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		return

	minimap_cam.global_position = Vector3(
		_player.global_position.x,
		CAM_HEIGHT,
		_player.global_position.z
	)

	var half := CAM_SIZE * 0.5
	var map_x := clampf(_player.global_position.x / half, -1.0, 1.0)
	var map_y := clampf(-_player.global_position.z / half, -1.0, 1.0)
	player_dot.position = Vector2(
		MAP_PX * 0.5 + map_x * MAP_PX * 0.5 - 4.0,
		MAP_PX * 0.5 + map_y * MAP_PX * 0.5 - 4.0
	)
	rotation = 0.0
