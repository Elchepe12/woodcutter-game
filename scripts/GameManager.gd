# GameManager.gd
extends Node

const PLAYER_SCENE = preload("res://scenes/Player.tscn")

@onready var players_container: Node3D = $Players

func _ready():
	var player = PLAYER_SCENE.instantiate()
	player.name = "1"
	player.position = Vector3(0, 1, 12)
	players_container.add_child(player)
