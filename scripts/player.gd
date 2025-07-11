class_name Player
extends CharacterBody2D

@export var initial_max_speed: float = 450.0
var max_speed: float = initial_max_speed

@export var initial_acceleration: float = 800.0
var acceleration: float = initial_acceleration

@export var pickable_object_scene: PackedScene

var pickable_objects: Array[PickableObject] = []
var picked_object: PickableObject = null
var nearby_tool: Tool = null
var nearby_item_sources: Array[ItemSource] = []
var nearby_customer: Customer

var applied_effect: PotionEffect = null

@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Pivot/Sprite2D
@onready var animation_tree: AnimationTree = $Pivot/AnimationTree
@onready var playback: Variant = animation_tree["parameters/playback"]
@onready var pivot: Node2D = $Pivot
@onready var effect_timer: Timer = $EffectTimer

@onready var item_pickup_area: Area2D = $ItemPickupArea
@onready var tool_interaction_area: Area2D = $ToolInteractionArea
@onready var source_interaction_area: Area2D = $SourceInteractionArea
@onready var customer_interaction_area: Area2D = $CustomerInteractionArea

@onready var marker_down: Marker2D = $PickUpMarkers/MarkerDown
@onready var object_root: Node2D = self.find_parent("Store").get_child(5)

func _ready() -> void:
	item_pickup_area.area_entered.connect(_on_item_pickup_area_area_entered)
	item_pickup_area.area_exited.connect(_on_item_pickup_area_area_exited)
	tool_interaction_area.area_entered.connect(_on_tool_interaction_area_area_entered)
	tool_interaction_area.area_exited.connect(_on_tool_interaction_area_area_exited)
	source_interaction_area.area_entered.connect(_on_source_interaction_area_area_entered)
	source_interaction_area.area_exited.connect(_on_source_interaction_area_area_exited)
	customer_interaction_area.area_entered.connect(_on_customer_interaction_area_area_entered)
	customer_interaction_area.area_exited.connect(_on_customer_interaction_area_area_exited)
	
	effect_timer.timeout.connect(remove_effect)

func setup(player_object: Statics.PlayerData) -> void:
	# Seteamos el nombre del nodo de forma de que sea unico
	name = str(player_object.id)
	label.text = player_object.name
	
	if player_object.role == Statics.Role.ROLE_A:
		#sprite.self_modulate = Color.RED
		pass
	elif player_object.role == Statics.Role.ROLE_B:
		#sprite.self_modulate = Color.BLUE
		pass
	else:
		#sprite.self_modulate = Color.GREEN
		pass
	
	#Seteamos la autoridad del peer con id: player_object.id sobre este nodo de jugador
	set_multiplayer_authority(player_object.id)

func _input(event: InputEvent) -> void:
	if is_multiplayer_authority():
		
		# Recogida de items: Pulsacion de Espacio
		if event.is_action_pressed("ui_accept"):
			
			# Si hay objetos alrededor y no tengo uno en la mano:
			if pickable_objects and not picked_object:
				#Debug.log("Objeto Recogido")
				var object: PickableObject = pickable_objects.pop_front()
				
				# Si el objeto no estaba recogido, lo recogemos
				if not object.picked_up:
					picked_object = object
					configure_picked_object(object, true)
					
					if picked_object.item_type.is_potion():
						Debug.log("Timer de pocion cancelado")
						picked_object.cancel_timer.rpc()
				else:
					# No recuerdo si este else es necesario o que hacia
					Debug.log("Caso extraño")
					pickable_objects.append(object)
		
			elif picked_object:
				#Debug.log("Objeto soltado")
				configure_picked_object(picked_object, false)
				if picked_object.item_type.is_potion():
					picked_object.start_timer.rpc()
				
				picked_object = null
		
		# Deposito de items en utensilios: Pulsacion de Q
		if event.is_action_pressed("interact"):
			if nearby_tool and picked_object:
				#Debug.log("Solicitud de deposito de " + str(picked_object.item_type) + " enviada al server")
				nearby_tool.rpc_id(1, "request_server_add_ingredient", picked_object.item_type.ID, multiplayer.get_unique_id())
			
			elif nearby_tool and not picked_object:
				#Debug.log("Solicitud de recogida de producto enviada al server")
				nearby_tool.request_crafted_item.rpc_id(1)
			
			elif nearby_item_sources and not picked_object:
				# Hay un item source cerca y podemos recoger objeto nuevo
				#Debug.log("Solicitud de nuevo objeto enviada")
				var source: ItemSource = nearby_item_sources.pop_front()
				source.request_object.rpc(object_root.get_path())
				
				nearby_item_sources.append(source)
			
			elif nearby_customer and picked_object:
				#Debug.log("Entregando " + picked_object.item_type.item_name + " al cliente")
				nearby_customer.receive_product_request.rpc_id(1, picked_object.item_type.ID, multiplayer.get_unique_id())
			
			elif nearby_customer and not picked_object:
				nearby_customer.toggle_dialog()

@rpc("any_peer", "call_local", "reliable")
func confirm_object_deposited() -> void:
	# Si tenemos un objeto, ahora lo eliminamos
	#Debug.log("Objeto destruido")
	picked_object.destroy.rpc()

@rpc("any_peer", "call_local", "reliable")
func reject_object_deposited() -> void:
	# Objeto fue rechazado
	pass

@rpc("any_peer", "call_local", "reliable")
func receive_object(object_path: NodePath) -> void:
	#Debug.log("Objeto recibido")
	#Debug.log(object_path)
	var object: PickableObject = get_node(object_path)
	
	if not object:
		# Si por algun motivo el objeto es nulo, no hacemos nada
		#Debug.log("Error: Objeto nulo")
		return
	
	picked_object = object
	configure_picked_object(object, true)

@rpc("any_peer", "call_local", "reliable")
func receive_crafted_item(crafted_item_id: int) -> void:
	#Debug.log("Generando item")
	
	var object_instance: PickableObject = pickable_object_scene.instantiate()
	object_root.add_child(object_instance)
	object_instance.configure(crafted_item_id)
	
	configure_picked_object(object_instance, true)
	picked_object = object_instance

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		# Equivalente a get_axis pero para dos ejes
		
		play_movement_animations.rpc(move_input)
		
		for i in get_slide_collision_count():
			# Obtenemos los objetos con los que colisionamos
			var collision: KinematicCollision2D = get_slide_collision(i)
			
			# Por cada uno de ellos, calculamos la componente del vector velocidad que va hacia la pared/objeto
			# y se la restamos a la velocidad. Asi dejamos de acelerar hacia la pared, y podemos deslizarnos aun por ella.
			var normal_projected_velocity: Vector2 = velocity.dot(collision.get_normal()) * collision.get_normal()
			velocity = velocity - normal_projected_velocity
			
		velocity = velocity.move_toward(move_input * max_speed, acceleration * delta)
		sync_data.rpc(position, velocity)
		
		# Si tenemos un objeto recogido, lo movemos
		if picked_object:
			picked_object.sync_picked_position.rpc(position + marker_down.position)
	
	# Queremos que se mueva tenga o no autoridad
	move_and_slide()

@rpc("authority", "call_local", "unreliable_ordered")
func sync_data(pos: Vector2, vel: Vector2) -> void:
	position = lerp(position, pos, 0.9)
	velocity = lerp(velocity, vel, 0.9)

@rpc("authority", "call_local", "unreliable")
func play_movement_animations(move_input: Vector2) -> void:
	if abs(move_input.x) > 0.2:
		pivot.scale.x = -sign(move_input.x)
		playback.travel("horizontal_walk")
	elif move_input.y > 0:
		playback.travel("downwards_walk")
	elif move_input.y < 0:
		playback.travel("upwards_walk")
	else:
		playback.travel("idle")

func get_current_effect() -> PotionEffect:
	return applied_effect

func start_effect_timer(duration: float) -> void:
	effect_timer.start(duration)

func remove_effect() -> void:
	max_speed = initial_max_speed
	acceleration = initial_acceleration
	applied_effect = null

func configure_picked_object(object: PickableObject, picked_up: bool) -> void:
	object.pickup_and_disable_interaction.rpc(picked_up)

func _on_item_pickup_area_area_entered(area: Area2D) -> void:
	if is_multiplayer_authority():
		#Debug.log("Objeto detectado")
		pickable_objects.append(area.get_parent())

func _on_item_pickup_area_area_exited(area: Area2D) -> void:
	if is_multiplayer_authority():
		#Debug.log("Objeto sale")
		pickable_objects.erase(area.get_parent())

func _on_tool_interaction_area_area_entered(area: Area2D) -> void:
	#Debug.log("Entra utensilio")
	nearby_tool = area.get_parent()

func _on_tool_interaction_area_area_exited(_area: Area2D) -> void:
	#Debug.log("Sale utensilio")
	nearby_tool = null

func _on_source_interaction_area_area_entered(area: Area2D) -> void:
	#Debug.log("Item Source detectado")
	nearby_item_sources.append(area.get_parent())

func _on_source_interaction_area_area_exited(area: Area2D) -> void:
	#Debug.log("Item source sale")
	nearby_item_sources.erase(area.get_parent())

func _on_customer_interaction_area_area_entered(area: Area2D) -> void:
	#Debug.log("Customer entra")
	nearby_customer = area.get_parent()

func _on_customer_interaction_area_area_exited(_area: Area2D) -> void:
	#Debug.log("Customer sale")
	nearby_customer = null
