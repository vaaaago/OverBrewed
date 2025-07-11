extends Node

signal players_updated
signal player_updated(id: int)
signal vote_updated(id: int)
signal player_index_received()

signal register_ready_signal
signal customer_register_ready_signal
signal customer_request_register_ready_signal

var item_folder_path: String = "res://resources/Items/"
var product_folder_path: String = "res://resources/Product/"
var customer_folder_path: String = "res://resources/Customers/"
var customer_request_folder_path: String = "res://resources/Customer_requests/"

var item_register: Dictionary[int, Item] = {}
var register_ready: bool = false

var customer_register: Dictionary[int, CustomerResource] = {}
var customer_register_ready: bool = false

var customer_request_register: Dictionary[int, CustomerRequest] = {}
var customer_request_register_ready: bool = false


@export var multiplayer_test: bool = false
@export var use_roles: bool = true
@export var unique_roles: bool = true # won't start with repeated roles
@export var all_roles: bool = true # won't start if all roles aren't selected
@export var min_players: int = 2 # won't start if there are at least these players
@export var fill_screen: bool = true
@export var test_players: Array[PlayerDataResource] = [] # first one is server
@export var main_scene: PackedScene

var victory_screen_node: CanvasLayer
var defeat_screen_node: CanvasLayer


var players: Array[Statics.PlayerData] = []
var change_window_scale: bool = true :
	set(value):
		var last_value: bool = change_window_scale
		change_window_scale = value
		if not change_window_scale:
			reset_window_scale()
		elif last_value != value:
			_update_window_scale()

var _is_window_small: bool = false
var _initial_window_scale_mode: int
var _initial_window_scale_aspect: int

@onready var player_id: Label = %PlayerId

func _init() -> void:
	# Cargamos recursos de items y productos
	load_item_resources_to_registers()
	load_customer_resources_to_register()
	load_customer_request_resources_to_register()
	
	register_ready = true
	register_ready_signal.emit()
	
	customer_register_ready = true
	customer_register_ready_signal.emit()
	
	customer_request_register_ready = true
	customer_request_register_ready_signal.emit()

func _ready() -> void:
	_initial_window_scale_mode = get_window().content_scale_mode
	_initial_window_scale_aspect = get_window().content_scale_aspect
	
	get_window().size_changed.connect(_handle_size_changed)
	_update_window_scale()
	get_tree().node_added.connect(_handle_node_added)
	
	if not OS.is_debug_build():
		multiplayer_test = false
		player_id.hide()

func get_all_files_from_directory(path : String, files: Array[String] = []) -> Array[String]:
	var resources: PackedStringArray = ResourceLoader.list_directory(path)
	for res: String in resources:
		files.append(path+res)
	return files

func load_item_resources_to_registers() -> void:
	for file in get_all_files_from_directory(item_folder_path):
		var item: Item = load(file)
		item_register[item.ID] = item
	
	for file in get_all_files_from_directory(product_folder_path):
		var product: Item = load(file)
		item_register[product.ID] = product

func load_customer_resources_to_register() -> void:
	for file in get_all_files_from_directory(customer_folder_path):
		var customer: CustomerResource = load(file)
		customer_register[customer.ID] = customer

func load_customer_request_resources_to_register() -> void:
	for file in get_all_files_from_directory(customer_request_folder_path):
		var request: CustomerRequest = load(file)
		customer_request_register[request.ID] = request

func sort_players() -> void:
	players.sort_custom(func(a: Statics.PlayerData, b: Statics.PlayerData) -> bool: return a.index < b.index)

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
	sort_players()
	players_updated.emit()


func remove_player(id: int) -> void:
	for i in players.size():
		if players[i].id == id:
			players.remove_at(i)
			break
	
	if multiplayer.is_server():
		var player_indices: Dictionary = {}
		for i in players.size():
			players[i].index = i
			player_indices[players[i].id] = i
		update_indices.rpc(player_indices)
	players_updated.emit()


func get_player(id: int) -> Statics.PlayerData:
	for player in players:
		if player.id == id:
			return player
	return null


func get_current_player() -> Statics.PlayerData:
	return get_player(multiplayer.get_unique_id())


@rpc("reliable")
func update_indices(player_indices: Dictionary) -> void:
	for player: Statics.PlayerData in Game.players:
		if player.id in player_indices:
			player.index = player_indices[player.id]
			if player.id == multiplayer.get_unique_id():
				Debug.index = player.index
				Debug.add_to_window_title("Client %d" % player.index)
	sort_players()
	players_updated.emit()


@rpc("any_peer", "reliable", "call_local")
func set_player_role(id: int, role: Statics.Role) -> void:
	var player: Statics.PlayerData = get_player(id)
	player.role = role
	player_updated.emit(id)


func set_current_player_role(role: Statics.Role) -> void:
	set_player_role.rpc(multiplayer.get_unique_id(), role)


@rpc("any_peer", "reliable", "call_local")
func set_player_vote(id: int, vote: bool) -> void:
	var player: Statics.PlayerData = get_player(id)
	if not player:
		return
	player.vote = vote
	player_updated.emit(id)
	vote_updated.emit(id)


func set_current_player_vote(vote: bool) -> void:
	set_player_vote.rpc(multiplayer.get_unique_id(), vote)


func reset_votes() -> void:
	for player in players:
		set_player_vote.rpc(player.id, false)


func is_online() -> bool:
	return not multiplayer.multiplayer_peer is OfflineMultiplayerPeer and \
		multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED


func update_player_id() -> void:
	if not OS.is_debug_build():
		return
	if Debug.is_online():
		player_id.show()
		player_id.text = str(multiplayer.get_unique_id())
	else:
		player_id.hide()


func reset_window_scale() -> void:
	get_window().content_scale_mode = _initial_window_scale_mode
	get_window().content_scale_aspect = _initial_window_scale_aspect


func _handle_size_changed() -> void:
	if not change_window_scale:
		return
	
	var was_windows_small: Variant = _is_window_small
	#get_window().min_size = Vector2i(1280, 720)
	_is_window_small =  get_window().size.x < 1280 or get_window().size.y < 720

	if was_windows_small == _is_window_small:
		return
	
	_update_window_scale()


func _update_window_scale() -> void:
	if _is_window_small:
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	else:
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func _handle_node_added(node: Node) -> void:
	if node.get_parent() == get_window():
		# Scene has been changed
		change_window_scale = node is MainMenu or node is LobbyHostScreen or \
			node is LobbyJoinScreen or node is LobbyWaitingScreen or node is Credits
