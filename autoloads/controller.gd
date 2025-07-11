extends Control

@export var customer_scene: PackedScene

@export var max_customers: int = 4
@export var spawn_delay: float = 15.0
@export var max_wait_time: float =  80.0
#@export var customer_scenes: Array[PackedScene] # contiene 4 escenas diferentes

var customer_array := []
var spawners: Array = []  # Spawner nodes
var occupied_spawners: Dictionary = {}  # spawner_node -> cliente

var score: int = 0
@onready var score_label: Label = $ScorePanel/ScoreLabel

@export var level_duration: int = 360  # 6 minutos
@export var required_score: int = 1000
var time_left: int = level_duration
var level_ended := false

func _ready() -> void:
	set_multiplayer_authority(1) # El server tiene la autoridad sobre el controller
	
	$LevelTimer.start()
	start_timer_update()
	
	# Obtener todos los spawners hijos del nodo "Spawners"
	var spawner_parent: Node2D = get_node("../CustomerSpawns")  # ajusta si estás en otro nivel
	spawners = spawner_parent.get_children()
	update_score(0)
	
	if multiplayer.is_server():
		spawn_customers_loop()

func spawn_customers_loop() -> void:
	if is_multiplayer_authority():
		await get_tree().create_timer(spawn_delay).timeout
		
		while true:
			if customer_array.size() < max_customers and get_available_spawner():
				spawn_client()
			
			await get_tree().create_timer(spawn_delay).timeout

@rpc("call_local")
func spawn_client_sync(customer_id: int, request_id: int, spawn_name: String) -> void:
	var client_instance: Customer = customer_scene.instantiate()
	
	# Agregar el cliente al spawner correspondiente
	var spawner: Marker2D = $"../CustomerSpawns".get_node(spawn_name)
	spawner.add_child(client_instance)
	
	client_instance.global_position = spawner.global_position
	client_instance.configure(customer_id, request_id)

	# Configurar tiempo de espera
	client_instance.customer_wait_time = max_wait_time
	
	# Cuando reciba el producto, sumar puntaje
	if client_instance.has_signal("received_product"):
		client_instance.received_product.connect(_received_product_signal_received)

	# Cuando el cliente se vaya, limpiar
	client_instance.despawned.connect(func() -> void:
		customer_array.erase(client_instance)
		occupied_spawners.erase(spawner)
		)

func _received_product_signal_received() -> void:
	#Debug.log("Señal recibida")
	update_score.rpc(100)

func spawn_client() -> void:
	var available_spawners: Array[Marker2D] = get_available_spawner()
	
	if available_spawners.is_empty():
		return

	var spawn_node: Marker2D = available_spawners.pick_random()
	var spawn_name: String = spawn_node.name
	
	var customer_id: int = randi() % Game.customer_register.size()
	var request_id: int = randi() % Game.customer_request_register.size()
	
	# Llamar a todos los clientes para que spawneen lo mismo
	spawn_client_sync.rpc(customer_id, request_id, spawn_name)

func get_available_spawner() -> Array[Marker2D]:
	var available: Array[Marker2D] = []
	
	for child: Marker2D in $"../CustomerSpawns".get_children():
		if child.get_child_count() == 0:
			available.append(child)
	
	return available

@rpc("any_peer", "call_local", "reliable")
func update_score(score_value: int) -> void:
	score += score_value
	#Debug.log("Score actualizado: " + str(score))
	score_label.text = "%d" % score
	
func start_timer_update() -> void:
	# Actualiza el reloj visual cada segundo
	var ticker := Timer.new()
	
	ticker.wait_time = 1.0
	ticker.one_shot = false
	ticker.autostart = true
	
	ticker.timeout.connect(update_time)
	add_child(ticker)

func update_time() -> void:
	if level_ended:
		return
	
	time_left -= 1
	
	var minutes: int = time_left / 60
	var seconds: int = time_left % 60
	
	$TimePanel/TimeLabel.text = "%02d:%02d" % [minutes, seconds]
	
	if time_left <= 0:
		end_level()

func end_level() -> void:
	level_ended = true
	$LevelTimer.stop()
	
	if score >= required_score:
		#Debug.log("win")
		var victory: CanvasLayer = Game.victory_screen_node
		victory.visible = true
	else:
		#Debug.log("lose")
		var defeat: CanvasLayer = Game.defeat_screen_node
		defeat.visible = true
