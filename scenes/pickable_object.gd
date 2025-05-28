class_name PickableObject
extends RigidBody2D

@onready var collision_area_shape: CollisionShape2D = $CollisionAreaShape
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_area_shape: CollisionShape2D = $PickupArea/PickupAreaShape

var picked_up: bool = false

@rpc("any_peer", "call_local", "unreliable_ordered")
func pickup_and_disable_interaction(state: bool) -> void:
	picked_up = state
	collision_area_shape.set_deferred("disabled", state)
	pickup_area_shape.set_deferred("disabled", state)

func force_update():
	var radius = pickup_area_shape.shape.radius
	pickup_area_shape.shape.radius = 0
	await get_tree().create_timer(0.1).timeout
	pickup_area_shape.shape.radius = radius

@rpc("any_peer", "call_local", "unreliable_ordered")
func sync_picked_position(pos: Vector2) -> void:
	set_position(pos)
