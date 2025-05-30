class_name ItemSource
extends Node2D

@export var item_type: Item
@export var pickable_object_scene: PackedScene
@onready var sprite: Sprite2D = $Sprite

func _init() -> void:
	# Server tendra autoridad sobre fuentes de items
	set_multiplayer_authority(1) 

func _ready() -> void:
	if item_type:
		sprite.texture = item_type.texture
		sprite.scale.x = item_type.texture_scale
		sprite.scale.y = item_type.texture_scale

@rpc("any_peer", "call_local", "reliable")
func request_object(object_root_path: NodePath) -> void:
	var object_instance: PickableObject = pickable_object_scene.instantiate()
	var object_root = get_node(object_root_path)
	object_root.add_child(object_instance)
	object_instance.configure(item_type.ID)
	
	var object_path: NodePath = object_instance.get_path()
	var player: Player = Game.get_current_player().instance
	var remote_sender_id = multiplayer.get_remote_sender_id()
	player.receive_object.rpc_id(remote_sender_id, object_path)

func get_item_type_id() -> int:
	return item_type.ID
