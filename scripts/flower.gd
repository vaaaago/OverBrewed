extends ItemSource

func _ready() -> void:
	if item_type:
		sprite.texture = item_type.texture
		sprite.scale.x = item_type.texture_scale
		sprite.scale.y = item_type.texture_scale

func play_pickup_animation() -> void:
	anim.play("flower_pickup")
