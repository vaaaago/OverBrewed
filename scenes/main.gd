extends Node2D


@onready var lobby_button: Button = %LobbyButton
@onready var menu_button: Button = %MenuButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	lobby_button.pressed.connect(func(): Lobby.go_to_lobby.rpc())
	menu_button.pressed.connect(Lobby.go_to_menu)
	quit_button.pressed.connect(func(): get_tree().quit())
