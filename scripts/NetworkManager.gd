# NetworkManager.gd — Autoload
extends Node

const PORT = 7777
const MAX_PLAYERS = 4

signal player_joined(id: int)
signal player_left(id: int)
signal connected_to_host
signal connection_failed

func host():
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		push_error("Error al crear servidor: %d" % err)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("Servidor iniciado en puerto %d" % PORT)

func join(ip: String):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, PORT)
	if err != OK:
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(func(): connected_to_host.emit())
	multiplayer.connection_failed.connect(func(): connection_failed.emit())
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func disconnect_game():
	multiplayer.multiplayer_peer = null

func is_host() -> bool:
	return multiplayer.is_server()

func my_id() -> int:
	return multiplayer.get_unique_id()

func _on_peer_connected(id: int):
	print("Jugador conectado: %d" % id)
	player_joined.emit(id)

func _on_peer_disconnected(id: int):
	print("Jugador desconectado: %d" % id)
	player_left.emit(id)
