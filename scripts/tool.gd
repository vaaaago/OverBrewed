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

func get_ingredient_count() -> int:
	return ingredient_count

func get_max_ingredients() -> int:
	return total_ingredients

func request_add_ingredient(ingredient: Item):
	# Implementaremos logica para enviar solicitud al servidor, y que el se 
	# encarge de gestionar el estado del caldero, y llamar a rpc en todos los peers.
	# en obsidian deje el primer resultado que me dio chatGPT
	
	# Quiza conviene hacerse un diagrama
	pass

@rpc("any_peer", "call_local", "unreliable_ordered")
func add_ingredient(ingredient: Item) -> void:
	Debug.log("Ingrediente agregado")
	
	if ingredient_count < total_ingredients:
		var frame: TextureRect = icon_container.get_child(ingredient_count)
		var sprite: TextureRect = frame.get_child(0).get_child(0)
		
		sprite.texture = ingredient.texture
		frame.visible = true
		
		var sync_dict: Dictionary = {}
		
		ingredient_dict[ingredient] += 1
		ingredient_array.append(ingredient)
		ingredient_count += 1
		
		Debug.log(ingredient_dict)
		
		if get_ingredient_count() == get_max_ingredients():
			Debug.log("Momento de craftear")
			
			timer.start()
			await timer.timeout
			playback.travel("red_cauldron_smoke")
			
			item_ready = true
			
			for ig in ingredient_array:
				ingredient_dict[ig] = 0
			
			for fr: TextureRect in icon_container.get_children():
				fr.visible = false

func pickup_item() -> PickableObject:
	# Asumiendo que hay un objeto listo para recoger
	var object_instance = object_scene.instantiate()
	object_instance.item_type = output_item
	return object_instance

func sync_instances(sync_dict: Dictionary) -> void:
	pass
