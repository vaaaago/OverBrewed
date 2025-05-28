class_name ItemSource
extends Sprite2D

@export var item_type: Item
var item_id: int
var item_name: String

func _ready() -> void:
	item_name = item_type.item_name
	item_id = item_type.ID
	texture = item_type.texture
