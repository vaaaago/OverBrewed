extends Node


@export var go_to_lobby_on_disconnect := true


func _ready():
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_connected_to_server() -> void:
	Debug.log("Connected to server")


func _on_connection_failed() -> void:
	Debug.log("Connection Failed")


func _on_peer_connected(id: int) -> void:
	Debug.log("Peer connected %d" % id)


func _on_peer_disconnected(id: int) -> void:
	Debug.log("Peer disconnected %d" % id)
	if go_to_lobby_on_disconnect:
		go_to_lobby()


func _on_server_disconnected() -> void:
	Debug.log("Server disconnected")


func go_to_lobby() -> void:
	get_tree().change_scene_to_file("res://lobby/lobby_screen.tscn")
	multiplayer.multiplayer_peer.close()
