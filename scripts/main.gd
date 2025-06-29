extends Node2D

@export var player_scene: PackedScene 

@onready var player_root: Node2D = $PlayerRoot
@onready var spawn_points: Node2D = $SpawnPoints
@onready var mortarAnim := $Tools/mortar/AnimationPlayer


func _ready() -> void:
	for i in Game.players.size():
		var player_object = Game.players[i]
		var player_instance = player_scene.instantiate()
		
		player_root.add_child(player_instance)
		player_instance.setup(player_object)
		player_instance.global_position = spawn_points.get_child(i).global_position
		
		# Guardamos una referencia al nodo del jugador en su PlayerData
		player_object.instance = player_instance
