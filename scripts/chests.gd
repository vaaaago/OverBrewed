extends ItemSource

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect/MarginContainer/TextureRect

func _ready() -> void:
	texture_rect.texture = item_type.texture

func play_pickup_animation() -> void:
	anim.play("open_chest")
