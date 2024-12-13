class_name LobbyJoinScreen
extends Control

@onready var player_name: LineEdit = %PlayerName
@onready var ip: LineEdit = %IP
@onready var join_button: Button = %JoinButton
@onready var back_button: Button = %BackButton
@onready var error_label: Label = %ErrorLabel
@onready var error_timer: Timer = $ErrorTimer

func _ready() -> void:
	player_name.text = OS.get_environment("USERNAME") + (str(randi() % 1000) if OS.has_feature("editor")
 else "")
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://ui/main_menu.tscn"))
	join_button.pressed.connect(_join)
	error_timer.timeout.connect(func(): error_label.hide())
	error_label.hide()
	back_button.pressed.connect(func(): Lobby.go_to_menu())


func _join() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip.text if ip.text else "localhost", Statics.PORT)
	if err != OK:
		error_label.show()
		error_timer.stop()
		error_timer.start()
		return
	
	multiplayer.multiplayer_peer = peer
	Game.add_player(Statics.PlayerData.new(multiplayer.get_unique_id(), player_name.text))

	get_tree().change_scene_to_file("res://lobby/waiting_screen.tscn")
