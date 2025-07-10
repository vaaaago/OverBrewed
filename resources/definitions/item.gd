class_name Item
extends Resource

@export var item_name: String
@export var ID: int
@export var texture: Texture2D
@export var texture_scale: float = 1.0
@export var pickable_texture_scale: float = 2.0
@export var is_potion_item: bool = false
@export var potion_effect: PotionEffect

func _to_string() -> String:
	return item_name

func is_potion() -> bool:
	return is_potion_item
