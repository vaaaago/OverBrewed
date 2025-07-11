class_name Tool
extends StaticBody2D

@export var total_ingredients: int
@export var recipe_array: Array[CraftingRecipe]

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_area_shape: CollisionShape2D = $InteractionArea/InteractionAreaShape
@onready var icon_container: HBoxContainer = $MarginContainer/HBoxContainer

@onready var timer: Timer = $Timer
@onready var animation_tree: AnimationTree = $Sprite2D/AnimationTree
@onready var playback: Variant = animation_tree["parameters/playback"]

# Variables sobre las que el server tiene autoridad
var ingredient_id_array: Array[int]
var ingredient_count: int = 0

@export var pickable_object_scene: PackedScene

var output_item: Item = null

func _init() -> void:
	# El server se encargara de gestionar los utensilios
	set_multiplayer_authority(1)

func _ready() -> void:
	for frame: TextureRect in icon_container.get_children():
		frame.visible = false

@rpc("any_peer", "call_local", "reliable")
func request_server_add_ingredient(ingredient_ID: int, request_peer_id: int) -> void:
	# Este metodo se ejecuta en el server, y valida una solicitud de un peer para 
	# depositar un item
	var ingredient: Item = Game.item_register[ingredient_ID]
	
	if !is_multiplayer_authority():
		# Si no es el server, ignoramos
		return
	
	# Chequeamos si el total de ingredientes se ha superado:
	if ingredient_count < total_ingredients and not output_item:
		# Como fue aceptado, actualizamos el estado de todos los peers
		rpc("sync_client_ingredient_state", ingredient.ID)
		
		# Ahora debemos notificar al jugador/peer que hizo la request que el objeto se deposito
		# Para que lo pueda eliminar
		var player: Player = Game.get_player(request_peer_id).instance
		player.rpc_id(request_peer_id, "confirm_object_deposited")
		
		# Si tras actualizar el estado, se tienen los ingredientes totales, iniciamos crafteo
		if ingredient_count == total_ingredients:
			timer.start()
			await timer.timeout
			
			# Mejorar esta logica para actuar diferente cuando el crafteo falla,
			# porque ahora mismo el caldero queda con la animacion aunque no haya crafteado nada util.
			craft_item()
		
	else:
		rpc_id(request_peer_id, "reject_object_deposited")

@rpc("authority", "call_local", "reliable")
func sync_client_ingredient_state(ingredient_added_ID: int) -> void:
	var ingredient_added: Item = Game.item_register[ingredient_added_ID]
	
	# Si no es el server, actualizamos variables
	#ingredient_dict[ingredient_added] += 1
	ingredient_id_array.append(ingredient_added_ID)
	ingredient_count += 1
	
	var frame: TextureRect = icon_container.get_child(ingredient_count - 1)
	var sprite: TextureRect = frame.get_child(0).get_child(0)
		
	sprite.texture = ingredient_added.texture
	frame.visible = true

@rpc("authority", "call_local", "reliable")
func reset_state() -> void:
	while ingredient_id_array.size() > 0:
		@warning_ignore("standalone_expression")
		Game.item_register[ingredient_id_array.pop_back()]
		#ingredient_dict[ig] = 0
		ingredient_count -= 1
		
		for fr: TextureRect in icon_container.get_children():
			fr.visible = false

func craft_item() -> void:
	for recipe: CraftingRecipe in recipe_array:
		if recipe.can_craft(ingredient_id_array):
			output_item = recipe.output
			
			# Crafteo exitoso
			var anim: String = "crafted_state"
			sync_animation.rpc(anim)
			reset_state.rpc()
			return
	
	# Crafteo fallido
	reset_state.rpc()
	return

@rpc("any_peer", "call_local", "reliable")
func request_crafted_item() -> void:
	if !is_multiplayer_authority():
		#Debug.log("No es server")
		return
	
	if output_item:
		#Debug.log("Solicitud aceptada")
		var remote_sender_id: int = multiplayer.get_remote_sender_id()
		var player: Player = Game.get_player(remote_sender_id).instance
		
		var output_item_id: int = output_item.ID
		output_item = null
		
		var anim: String = "idle_state"
		sync_animation.rpc(anim)
		player.receive_crafted_item.rpc(output_item_id)
	else:
		#Debug.log("Nada por recoger")
		return

@rpc("authority", "call_local", "reliable")
func sync_animation(anim: String) -> void:
	playback.travel(anim)
