extends Node2D
@onready var victory: CanvasLayer = $victory
@onready var defeat: CanvasLayer = $defeat

func _ready() -> void:
	Game.victory_screen_node = victory
	Game.defeat_screen_node = defeat
	
	victory.visible = false
	defeat.visible = false
