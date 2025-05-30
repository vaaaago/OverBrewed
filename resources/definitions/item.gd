class_name Item
extends Resource

@export var item_name: String
@export var ID: int
@export var texture: Texture2D
@export var texture_scale: float = 1.0
@export var pickable_texture_scale = 2.0

func _to_string() -> String:
	return item_name
