extends CharacterBody2D

@export var max_speed = 400

@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D


func setup(player_object: Statics.PlayerData):
	# Seteamos el nombre del nodo de forma de que sea unico
	name = str(player_object.id)
	label.text = player_object.name
	sprite.self_modulate = Color.RED if player_object.role == Statics.Role.ROLE_A else Color.BLUE
	
	#Seteamos la autoridad del peer con id: player_object.id sobre este nodo de jugador
	set_multiplayer_authority(player_object.id)

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		# Equivalente a get_axis pero para dos ejes
		
		position += max_speed * move_input * delta
		sync_position.rpc(position)

@rpc("authority", "call_local", "unreliable_ordered")
func sync_position(pos: Vector2) -> void:
	position = lerp(position, pos, 0.5)
