extends CharacterBody2D

@export var max_speed = 450
@export var acceleration = 800

var pickable_objects: Array[PickableObject] = []
var picked_object: PickableObject = null

@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Pivot/Sprite2D
@onready var animation_tree: AnimationTree = $Pivot/AnimationTree
@onready var playback = animation_tree["parameters/playback"]
@onready var pivot: Node2D = $Pivot
@onready var pickup_area: Area2D = $PickupArea

@onready var marker_down: Marker2D = $PickUpMarkers/MarkerDown



func _ready() -> void:
	pickup_area.area_entered.connect(_on_pickup_area_area_entered)
	pickup_area.area_exited.connect(_on_pickup_area_area_exited)

func setup(player_object: Statics.PlayerData):
	# Seteamos el nombre del nodo de forma de que sea unico
	name = str(player_object.id)
	label.text = player_object.name
	
	if player_object.role == Statics.Role.ROLE_A:
		sprite.self_modulate = Color.RED
	elif player_object.role == Statics.Role.ROLE_B:
		sprite.self_modulate = Color.BLUE
	else:
		sprite.self_modulate = Color.GREEN
	
	#Seteamos la autoridad del peer con id: player_object.id sobre este nodo de jugador
	set_multiplayer_authority(player_object.id)

func _input(event: InputEvent) -> void:
	if is_multiplayer_authority():
		if event.is_action_pressed("ui_accept"):
			if pickable_objects and not picked_object:
				Debug.log("Objeto Recogido")
				var object = pickable_objects.pop_front()
				
				if not object.picked_up:
					picked_object = object
					configure_picked_object(object, true)
				else:
					pickable_objects.push_front(object)
			
			elif picked_object:
				Debug.log("Objeto soltado")
				configure_picked_object(picked_object, false)
				picked_object = null


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		# Equivalente a get_axis pero para dos ejes
		
		#Debug.log(pickable_objects)
		#Debug.log(picked_object)
		
		play_movement_animations.rpc(move_input)
		velocity = velocity.move_toward(move_input * max_speed, acceleration * delta)
		sync_data.rpc(position, velocity)
	
	# Queremos que se mueva tenga o no autoridad
	move_and_slide()
	
	# Si tenemos un objeto recogido, lo movemos
	if picked_object:
		picked_object.sync_picked_position.rpc(position + marker_down.position)

@rpc("authority", "call_local", "unreliable_ordered")
func sync_data(pos: Vector2, vel: Vector2) -> void:
	position = lerp(position, pos, 0.9)
	velocity = lerp(velocity, vel, 0.9)

@rpc("authority", "call_local", "unreliable")
func play_movement_animations(move_input: Vector2):
	if abs(move_input.x) > 0.2:
		pivot.scale.x = -sign(move_input.x)
		playback.travel("horizontal_walk")
	elif move_input.y > 0:
		playback.travel("downwards_walk")
	elif move_input.y < 0:
		playback.travel("upwards_walk")
	else:
		playback.travel("idle")

func configure_picked_object(object: PickableObject, picked_up: bool) -> void:
	picked_object.pickup_and_disable_interaction.rpc(picked_up)

func _on_pickup_area_area_entered(area: Area2D):
	if is_multiplayer_authority():
		Debug.log("Objeto detectado")
		pickable_objects.append(area.get_parent())
		
func _on_pickup_area_area_exited(area: Area2D):
	if is_multiplayer_authority():
		Debug.log("Objeto sale")
		pickable_objects.erase(area.get_parent())
