extends Control

#@export var client_scene: PackedScene
@export var max_customers: int = 4
@export var spawn_delay: float = 20.0
@export var customer_wait_time: float =  60.0

var customer_array := []

func _ready():
	spawn_customers_loop()

func spawn_customers_loop():
	await get_tree().create_timer(spawn_delay).timeout
	while customer_array.size() < max_customers:
		#spawn_client()
		await get_tree().create_timer(spawn_delay).timeout
