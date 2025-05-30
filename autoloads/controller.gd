extends Control


@export var max_customers: int = 4
@export var spawn_delay: float = 10.0
@export var max_wait_time: float =  60.0
@export var customer_scenes: Array[PackedScene] # contiene 4 escenas diferentes

var customer_array := []
var spawners: Array = []  # Spawner nodes
var occupied_spawners: Dictionary = {}  # spawner_node -> cliente

var score: int = 0
@onready var score_label: Label = $ScorePanel/ScoreLabel

@export var level_duration: int = 120  # 5 minutos
@export var required_score: int = 300
var time_left: int = level_duration
var level_ended := false

func _ready():
	set_multiplayer_authority(1) # El server tiene la autoridad sobre el controller
	
	$LevelTimer.start()
	start_timer_update()
	
	# Obtener todos los spawners hijos del nodo "Spawners"
	var spawner_parent = get_node("../CustomerSpawns")  # ajusta si estás en otro nivel
	spawners = spawner_parent.get_children()
	update_score(0)
	if multiplayer.is_server():
		spawn_customers_loop()

func spawn_customers_loop():
	await get_tree().create_timer(spawn_delay).timeout
	while true:
		if customer_array.size() < max_customers and get_available_spawner():
			spawn_client()
		await get_tree().create_timer(spawn_delay).timeout

@rpc("call_local")
func spawn_client_sync(client_index: int, spawn_name: String):	
	var client_scene = customer_scenes[client_index]
	var client_instance = client_scene.instantiate()
	
	# Agregar el cliente al spawner correspondiente
	var spawner = $"../CustomerSpawns".get_node(spawn_name)
	spawner.add_child(client_instance)
	client_instance.global_position = spawner.global_position

	# Configurar tiempo de espera
	client_instance.customer_wait_time = max_wait_time
	
	# Cuando reciba el producto, sumar puntaje
	if client_instance.has_signal("received_product"):
		client_instance.received_product.connect(_received_product_signal_received)

	# Cuando el cliente se vaya, limpiar
	client_instance.despawned.connect(func(_c):
		customer_array.erase(client_instance)
		occupied_spawners.erase(spawner)
		)

func _received_product_signal_received():
	Debug.log("Señal recibida")
	update_score.rpc(100)

func spawn_client():
	var available_spawners = get_available_spawner()
	if available_spawners.is_empty():
		return

	var spawn_node = available_spawners.pick_random()
	var spawn_name = spawn_node.name

	var random_index = randi() % customer_scenes.size()
	# Llamar a todos los clientes para que spawneen lo mismo
	spawn_client_sync.rpc(random_index, spawn_name)

func get_available_spawner() -> Array:
	var available := []
	for child in $"../CustomerSpawns".get_children():
		if child.get_child_count() == 0:
			available.append(child)
	return available

@rpc("any_peer", "call_local", "reliable")
func update_score(score_value: int):
	score += score_value
	Debug.log("Score actualizado: " + str(score))
	score_label.text = "%d" % score
	
func start_timer_update():
	# Actualiza el reloj visual cada segundo
	var ticker := Timer.new()
	ticker.wait_time = 1.0
	ticker.one_shot = false
	ticker.autostart = true
	ticker.timeout.connect(update_time)
	add_child(ticker)

func update_time():
	if level_ended:
		return
	time_left -= 1
	var minutes = time_left / 60
	var seconds = time_left % 60
	$TimePanel/TimeLabel.text = "%02d:%02d" % [minutes, seconds]
	if time_left <= 0:
		end_level()
		
func end_level():
	level_ended = true
	$LevelTimer.stop()
	if score >= required_score:
		print("win")
	else:
		print("lose")
