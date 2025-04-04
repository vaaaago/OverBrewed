extends CharacterBody2D

@export var max_speed = 450
@export var acceleration = 800

@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Pivot/Sprite2D


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

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		# Equivalente a get_axis pero para dos ejes
		
		velocity = velocity.move_toward(move_input * max_speed, acceleration * delta)
		sync_data.rpc(position, velocity)
	
	# Queremos que se mueva tenga o no autoridad
	move_and_slide()

@rpc("authority", "call_local", "unreliable_ordered")
func sync_data(pos: Vector2, vel: Vector2) -> void:
	position = lerp(position, pos, 0.8)
	velocity = lerp(velocity, vel, 0.8)
