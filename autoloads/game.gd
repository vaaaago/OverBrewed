extends Node

signal players_updated
signal player_updated(id)
signal player_index_received()

@export var multiplayer_test = false
@export var use_roles = false
@export var fill_screen = true
@export var test_players: Array[PlayerDataResource] = [] # first one is server
@export var main_scene: PackedScene

var players: Array[Statics.PlayerData] = []

@onready var player_id: Label = %PlayerId


func _ready() -> void:
	get_window().min_size = Vector2i(1280, 720)
	if !OS.is_debug_build():
		multiplayer_test = false
		player_id.hide()


func add_player(player: Statics.PlayerData) -> void:
	var existing_player: Statics.PlayerData = null
	for data in players:
		if data.id == player.id:
			existing_player = data
			break
	if existing_player:
		existing_player.update(player)
	else:
		players.append(player)
	players.sort_custom(func(a, b): return a.index < b.index)
	players_updated.emit()


func remove_player(id: int) -> void:
	for i in players.size():
		if players[i].id == id:
			players.remove_at(i)
			break
	players_updated.emit()


func get_player(id: int) -> Statics.PlayerData:
	for player in players:
		if player.id == id:
			return player
	return null


func get_current_player() -> Statics.PlayerData:
	return get_player(multiplayer.get_unique_id())


func get_player_index(id: int) -> int:
	for i in players.size():
		if players[i].id == id:
			return i
	return -1


func get_current_player_index() -> int:
	return get_player_index(multiplayer.get_unique_id())


@rpc("reliable")
func set_player_index(index: int) -> void:
	var player = get_current_player()
	player.index = index
	player_index_received.emit()
	Debug.add_to_window_title("(Client %d)" % index)
	Debug.index = index


func set_next_player_index(id: int) -> void:
	if not multiplayer.is_server():
		return
	var index = 0
	for player in Game.players:
		if player.index == index:
			index += 1
	set_player_index.rpc_id(id, index)


@rpc("any_peer", "reliable", "call_local")
func set_player_role(id: int, role: Statics.Role) -> void:
	var player = get_player(id)
	player.role = role
	player_updated.emit(id)


func set_current_player_role(role: Statics.Role) -> void:
	set_player_role.rpc(multiplayer.get_unique_id(), role)


func is_online() -> bool:
	return not multiplayer.multiplayer_peer is OfflineMultiplayerPeer and \
		multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED


func update_player_id() -> void:
	player_id.text = str(multiplayer.get_unique_id())
