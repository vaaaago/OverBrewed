class_name ItemSource
extends Node2D

@export var item_type: Item
@export var pickable_object_scene: PackedScene
@onready var sprite: Sprite2D = $Sprite
@onready var anim: AnimationPlayer = $AnimationPlayer

func _init() -> void:
	# Server tendra autoridad sobre fuentes de items
	set_multiplayer_authority(1) 

@rpc("any_peer", "call_local", "reliable")
func request_object(object_root_path: NodePath) -> void:
	var object_instance: PickableObject = pickable_object_scene.instantiate()
	var object_root: Node2D = get_node(object_root_path)
	object_root.add_child(object_instance)
	object_instance.configure(item_type.ID)
	
	var object_path: NodePath = object_instance.get_path()
	var player: Player = Game.get_current_player().instance
	var remote_sender_id: int = multiplayer.get_remote_sender_id()
	
	play_pickup_animation()
	player.receive_object.rpc_id(remote_sender_id, object_path)

func get_item_type_id() -> int:
	return item_type.ID

func play_pickup_animation() -> void:
	# Sobre-escrito por scripts hijos
	pass
