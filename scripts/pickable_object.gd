class_name PickableObject
extends RigidBody2D

@export var item_type: Item
@export var potion_effect_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_area_shape: CollisionShape2D = $CollisionAreaShape
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_area_shape: CollisionShape2D = $PickupArea/PickupAreaShape
@onready var timer: Timer = $Timer

var picked_up: bool = false

func _ready() -> void:
	if item_type:
		configure(item_type.ID)
	
	timer.timeout.connect(on_timer_timeout)

func configure(item_type_id: int) -> void:
	if not Game.register_ready:
		await Game.register_ready_signal
	
	#Debug.log("Configurando objeto")
	item_type = Game.item_register[item_type_id]
	sprite.texture = item_type.texture
	sprite.scale.x = item_type.pickable_texture_scale
	sprite.scale.y = item_type.pickable_texture_scale

@rpc("any_peer", "call_local", "unreliable_ordered")
func pickup_and_disable_interaction(state: bool) -> void:
	picked_up = state
	collision_area_shape.set_deferred("disabled", state)
	pickup_area_shape.set_deferred("disabled", state)

@rpc("any_peer", "call_local", "unreliable_ordered")
func sync_picked_position(pos: Vector2) -> void:
	set_position(pos)

@rpc("any_peer", "call_local", "reliable")
func destroy() -> void:
	self.queue_free()

@rpc("any_peer", "call_local", "reliable")
func start_timer() -> void:
	timer.start()

@rpc("any_peer", "call_local", "reliable")
func cancel_timer() -> void:
	if not timer.is_stopped():
		timer.stop()

func on_timer_timeout() -> void:
	#Debug.log("Timer pocion")
	collision_area_shape.set_deferred("disabled", true)
	pickup_area_shape.set_deferred("disabled", true)
	visible = false
	
	var potion_effect_instance: PotionArea = potion_effect_scene.instantiate()
	var parent: Node2D = get_parent()
	parent.add_child(potion_effect_instance)
	
	potion_effect_instance.configure(position, item_type.ID)
	timer.stop()
	
	await potion_effect_instance.finished
	destroy.rpc()
