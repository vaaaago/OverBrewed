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
	Game.update_player_id()


func _on_connection_failed() -> void:
	Debug.log("Connection Failed")


func _on_peer_connected(id: int) -> void:
	Debug.log("Peer connected %d" % id)
	
	# If it's server or I already have an index assigned
	if id == 1 or Game.get_current_player().index != -1:
		send_data.rpc_id(id, Game.get_current_player().to_dict())
		
	#
	#if multiplayer.is_server():
		## Assign an index
		#Game.set_player_index.rpc_id(id, Game.players.size())
	## A peer connected, send it my info
	#send_data.rpc_id(id, Game.get_current_player().to_dict())
	#if multiplayer.is_server():
		#Game.set_next_player_index(id)
		#for player_id in status:
			#set_player_ready.rpc_id(id, player_id, status[player_id])
		#status[id] = false


func _on_peer_disconnected(id: int) -> void:
	Debug.log("Peer disconnected %d" % id)
	if go_to_lobby_on_disconnect:
		go_to_lobby()


func _on_server_disconnected() -> void:
	Debug.log("Server disconnected")


func go_to_lobby() -> void:
	get_tree().change_scene_to_file("res://lobby/lobby_screen.tscn")
	multiplayer.multiplayer_peer.close()

@rpc("any_peer", "reliable")
func send_data(data: Dictionary) -> void:
	if multiplayer.is_server():
		# A new player sent its data to the server, assing an index
		data.index = Game.players.size()
		send_data.rpc(data)
	Debug.log("Player data from %s received" % data.name)
	Game.add_player(Statics.PlayerData.from_dict(data))
	if data.id == multiplayer.get_unique_id():
		Debug.index = data.index
		Debug.add_to_window_title("Client %d" % data.index)
