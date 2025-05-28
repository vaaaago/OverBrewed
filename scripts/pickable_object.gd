class_name PickableObject
extends RigidBody2D

@export var item_type: Item

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_area_shape: CollisionShape2D = $CollisionAreaShape
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_area_shape: CollisionShape2D = $PickupArea/PickupAreaShape

var picked_up: bool = false

func _ready() -> void:
	if item_type:
		sprite.texture = item_type.texture
		sprite.scale = Vector2(2,2)

@rpc("any_peer", "call_local", "unreliable_ordered")
func pickup_and_disable_interaction(state: bool) -> void:
	picked_up = state
	collision_area_shape.set_deferred("disabled", state)
	pickup_area_shape.set_deferred("disabled", state)

@rpc("any_peer", "call_local", "unreliable_ordered")
func sync_picked_position(pos: Vector2) -> void:
	set_position(pos)

@rpc("any_peer", "call_local", "unreliable_ordered")
func destroy() -> void:
	self.queue_free()
