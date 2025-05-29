extends Control


@export var max_customers: int = 4
@export var spawn_delay: float = 10.0
@export var max_wait_time: float =  60.0
@export var customer_scenes: Array[PackedScene] # contiene 4 escenas diferentes

var customer_array := []
var spawners: Array = []  # Spawner nodes
var occupied_spawners: Dictionary = {}  # spawner_node -> cliente

var score: int = 0
@onready var score_label: Label = $Panel/ScoreLabel


func _ready():
	# Obtener todos los spawners hijos del nodo "Spawners"
	var spawner_parent = get_node("../CustomerSpawns")  # ajusta si estás en otro nivel
	spawners = spawner_parent.get_children()
	update_score()
	spawn_customers_loop()

func spawn_customers_loop():
	await get_tree().create_timer(spawn_delay).timeout
	while true:
		if customer_array.size() < max_customers and get_available_spawner():
			spawn_client()
		await get_tree().create_timer(spawn_delay).timeout
		
func spawn_client():
	var scene = customer_scenes.pick_random()
	var client_instance = scene.instantiate()
	
	var spawner = get_available_spawner()
	if spawner == null:
		return  # no hay spawner disponible

	client_instance.position = spawner.global_position
	get_tree().current_scene.add_child(client_instance)

	customer_array.append(client_instance)
	occupied_spawners[spawner] = client_instance

	# Configurar tiempo de espera
	client_instance.customer_wait_time = max_wait_time
	
	# Cuando reciba el producto, sumar puntaje
	if client_instance.has_signal("received_product"):
		client_instance.received_product.connect(func(_c):
			score += 100
			update_score()
		)
	# Cuando el cliente se vaya, limpiar
	client_instance.despawned.connect(func(_c):
		customer_array.erase(client_instance)
		occupied_spawners.erase(spawner)
		)

func get_available_spawner() -> Node2D:
	for spawner in spawners:
		if not occupied_spawners.has(spawner):
			return spawner
	return null
	
func update_score():
	score_label.text = "%d" % score
