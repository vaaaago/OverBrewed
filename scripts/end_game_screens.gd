extends Node2D
@onready var victory: CanvasLayer = $victory
@onready var defeat: CanvasLayer = $defeat
@onready var button_win: TextureButton = $victory/ColorRect/Control/ButtonWin
@onready var button_defeat: TextureButton = $defeat/ColorRect/Control/ButtonDefeat




func _ready() -> void:
	Game.victory_screen_node = victory
	Game.defeat_screen_node = defeat
	
	victory.visible = false
	defeat.visible = false
	
	button_win.pressed.connect(Callable(Lobby, "go_to_lobby"))
	button_defeat.pressed.connect(Callable(Lobby, "go_to_lobby"))      
