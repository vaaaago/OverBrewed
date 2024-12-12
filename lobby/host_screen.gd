extends Control

@onready var player_name: LineEdit = %PlayerName
@onready var host_button: Button = %HostButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	player_name.text = OS.get_environment("USERNAME") + (str(randi() % 1000) if OS.has_feature("editor")
 else "")
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://ui/main_menu.tscn"))
	
	player_name.caret_column = player_name.text.length()
	player_name.grab_focus()
	host_button.pressed.connect(_host)


func _host() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(Statics.PORT, Statics.MAX_CLIENTS)
	if err != OK:
		return
	multiplayer.multiplayer_peer = peer
	Game.add_player(Statics.PlayerData.new(multiplayer.get_unique_id(), player_name.text, 0))
	Debug.add_to_window_title("Server")
	Game.update_player_id()
	get_tree().change_scene_to_file("res://lobby/waiting_screen.tscn")
