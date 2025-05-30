class_name Tool
extends StaticBody2D

@export var total_ingredients: int
@export var recipe_array: Array[CraftingRecipe]

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_area_shape: CollisionShape2D = $InteractionArea/InteractionAreaShape
@onready var icon_container: HBoxContainer = $MarginContainer/HBoxContainer

@onready var timer: Timer = $Timer
@onready var animation_tree: AnimationTree = $Sprite2D/AnimationTree
@onready var playback = animation_tree["parameters/playback"]

# Variables sobre las que el server tiene autoridad
var ingredient_id_array: Array[int]
var ingredient_count = 0

@export var pickable_object_scene: PackedScene

var output_item: Item = null

func _init() -> void:
	# El server se encargara de gestionar los utensilios
	set_multiplayer_authority(1)

func _ready() -> void:
	for frame: TextureRect in icon_container.get_children():
		frame.visible = false

@rpc("any_peer", "call_local", "reliable")
func request_server_add_ingredient(ingredient_ID: int, request_peer_id: int):
	# Este metodo se ejecuta en el server, y valida una solicitud de un peer para 
	# depositar un item
	var ingredient = Game.item_dict[ingredient_ID]
	
	if !is_multiplayer_authority():
		# Si no es el server, ignoramos
		return
	
	Debug.log("Recibida petición de " + Game.get_player(request_peer_id).name + " para añadir " + ingredient.item_name)
	
	# Chequeamos si el total de ingredientes se ha superado:
	if ingredient_count < total_ingredients:
		#Debug.log("Ingrediente " + ingredient.item_name + " aceptado.")
		
		# Como fue aceptado, actualizamos el estado de todos los peers
		rpc("sync_client_ingredient_state", ingredient.ID)
		
		# Ahora debemos notificar al jugador/peer que hizo la request que el objeto se deposito
		# Para que lo pueda eliminar
		var player: Player = Game.get_player(request_peer_id).instance
		player.rpc_id(request_peer_id, "confirm_object_deposited")
		
		# Si tras actualizar el estado, se tienen los ingredientes totales, iniciamos crafteo
		if ingredient_count == total_ingredients:
			#Debug.log("Momento de craftear")
			
			timer.start()
			await timer.timeout
			
			var anim: String = "red_cauldron_smoke"
			sync_animation.rpc(anim)
			
			craft_item()
			
			reset_state.rpc()
		
	else:
		#Debug.log("Ingrediente " + ingredient.item_name + " rechazado (caldero lleno).")
		rpc_id(request_peer_id, "reject_object_deposited")

@rpc("authority", "call_local", "reliable")
func sync_client_ingredient_state(ingredient_added_ID: int):
	var ingredient_added = Game.item_dict[ingredient_added_ID]
	
	# Si no es el server, actualizamos variables
	#ingredient_dict[ingredient_added] += 1
	ingredient_id_array.append(ingredient_added_ID)
	ingredient_count += 1
	
	var frame: TextureRect = icon_container.get_child(ingredient_count - 1)
	var sprite: TextureRect = frame.get_child(0).get_child(0)
		
	sprite.texture = ingredient_added.texture
	frame.visible = true

@rpc("authority", "call_local", "reliable")
func reset_state():
	while ingredient_id_array.size() > 0:
		var ig = Game.item_dict[ingredient_id_array.pop_back()]
		#ingredient_dict[ig] = 0
		ingredient_count -= 1
		
		for fr: TextureRect in icon_container.get_children():
			fr.visible = false

func craft_item():
	if output_item:
		#Debug.log("Ya hay un producto esperando ser recogido")
		return
	
	for recipe: CraftingRecipe in recipe_array:
		Debug.log(recipe.can_craft(ingredient_id_array))
		if recipe.can_craft(ingredient_id_array):
			output_item = recipe.output
			#Debug.log(output_item.item_name + " ha sido crafteado")
			return
	#Debug.log("Crafteo fallido")
	return

@rpc("any_peer", "call_local", "reliable")
func request_crafted_item() -> void:
	if !is_multiplayer_authority():
		#Debug.log("No es server")
		return
	
	if output_item:
		#Debug.log("Solicitud aceptada")
		var remote_sender_id = multiplayer.get_remote_sender_id()
		var player: Player = Game.get_player(remote_sender_id).instance
		
		var output_item_id = output_item.ID
		output_item = null
		
		var anim: String = "red_cauldron"
		sync_animation.rpc(anim)
		player.receive_crafted_item.rpc(output_item_id)
	else:
		#Debug.log("Nada por recoger")
		return

@rpc("authority", "call_local", "reliable")
func sync_animation(anim: String):
	playback.travel(anim)
