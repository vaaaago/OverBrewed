class_name tool
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
var ingredient_array: Array[Item]
var ingredient_dict: Dictionary
var ingredient_count = 0

@export var object_scene: PackedScene

var output_item: Item = null
var item_ready: bool = false

func _init() -> void:
	# El server se encargara de gestionar los utensilios
	set_multiplayer_authority(1)

func _ready() -> void:
	for item in Game.item_register:
		ingredient_dict[item] = 0
	
	for frame: TextureRect in icon_container.get_children():
		frame.visible = false

@rpc("any_peer","call_local", "reliable")
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
		Debug.log("Ingrediente " + ingredient.item_name + " aceptado.")
		
		# Como fue aceptado, actualizamos el estado de todos los peers
		rpc("sync_client_ingredient_state", ingredient.ID)
		
		# Ahora debemos notificar al jugador/peer que hizo la request que el objeto se deposito
		# Para que lo pueda eliminar
		var player: Player = Game.get_player(request_peer_id).instance
		player.rpc_id(request_peer_id, "confirm_object_deposited")
		
		# Si tras actualizar el estado, se tienen los ingredientes totales, iniciamos crafteo
		if ingredient_count == total_ingredients:
			Debug.log("Momento de craftear")
			
			timer.start()
			await timer.timeout
			
			var anim: String = "red_cauldron_smoke"
			sync_animation.rpc(anim)
			
			item_ready = true
			reset_state.rpc()
		
	else:
		Debug.log("Ingrediente " + ingredient.item_name + " rechazado (caldero lleno).")
		rpc_id(request_peer_id, "reject_object_deposited")

@rpc("authority", "call_local", "reliable")
func sync_client_ingredient_state(ingredient_added_ID: int):
	var ingredient_added = Game.item_dict[ingredient_added_ID]
	
	# Si no es el server, actualizamos variables
	ingredient_dict[ingredient_added] += 1
	ingredient_array.append(ingredient_added)
	ingredient_count += 1
	
	var frame: TextureRect = icon_container.get_child(ingredient_count - 1)
	var sprite: TextureRect = frame.get_child(0).get_child(0)
		
	sprite.texture = ingredient_added.texture
	frame.visible = true

@rpc("authority", "call_local", "reliable")
func reset_state():
	while ingredient_array.size() > 0:
		var ig = ingredient_array.pop_back()
		ingredient_dict[ig] = 0
		ingredient_count -= 1
		
		for fr: TextureRect in icon_container.get_children():
			fr.visible = false

@rpc("authority", "call_local", "reliable")
func sync_animation(anim: String):
	playback.travel(anim)

func pickup_item() -> PickableObject:
	# Asumiendo que hay un objeto listo para recoger
	var object_instance = object_scene.instantiate()
	object_instance.item_type = output_item
	return object_instance
