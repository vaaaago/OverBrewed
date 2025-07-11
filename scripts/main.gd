extends Node2D

@export var player_scene: PackedScene 
@export var character_textures: Array[Texture2D]

@onready var player_root: Node2D = $PlayerRoot
@onready var spawn_points: Node2D = $SpawnPoints
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	for i: int in Game.players.size():
		var player_object: Statics.PlayerData = Game.players[i]
		var player_instance: Player = player_scene.instantiate()
		
		player_root.add_child(player_instance)
		player_instance.setup(player_object)
		player_instance.global_position = spawn_points.get_child(i).global_position
		
		# Guardamos una referencia al nodo del jugador en su PlayerData
		player_object.instance = player_instance
		
		audio_stream_player_2d.finished.connect(_on_audio_playback_finished)

func _on_audio_playback_finished() -> void:
	audio_stream_player_2d.play()
