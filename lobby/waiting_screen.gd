extends Control

@onready var player_texture: TextureRect = %PlayerTexture
@onready var player_name: Label = %PlayerName
@onready var role_button: Button = %RoleButton
@onready var ready_button: Button = %ReadyButton

var _player_ready = false

func _ready() -> void:
	player_name.text = Game.get_current_player().name
	
	ready_button.pressed.connect(_toggle_ready)


func _toggle_ready() -> void:
	_player_ready = !_player_ready
	player_texture.modulate = Color.GREEN if _player_ready else Color.WHITE
