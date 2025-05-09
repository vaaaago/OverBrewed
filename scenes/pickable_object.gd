class_name PickableObject
extends RigidBody2D

@onready var collision_area_shape: CollisionShape2D = $CollisionAreaShape
@onready var pickup_area: Area2D = $PickupArea

var picked_up: bool = false

@rpc("any_peer", "call_local", "unreliable_ordered")
func pickup_and_disable_interaction(state: bool) -> void:
	picked_up = state
	collision_area_shape.disabled = state
	pickup_area.monitoring = not state
	pickup_area.monitorable = not state

@rpc("any_peer", "call_local", "unreliable_ordered")
func sync_picked_position(pos: Vector2) -> void:
	set_position(pos)
