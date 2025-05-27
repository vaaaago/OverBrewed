class_name tool
extends StaticBody2D

@export var total_ingredients: int

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_area_shape: CollisionShape2D = $InteractionArea/InteractionAreaShape
@onready var icon_container: HBoxContainer = $MarginContainer/HBoxContainer

enum types {AZUL, VERDE, ROJO}
var ingredient_array: Array[types] = []

func _ready() -> void:
	for icon: TextureRect in icon_container.get_children():
		icon.visible = false

func get_ingredient_count() -> int:
	return ingredient_array.size()

func get_max_ingredients() -> int:
	return total_ingredients

@rpc("any_peer", "call_local", "unreliable_ordered")
func add_ingredient(ingredient: PickableObject) -> void:
	Debug.log("Ingrediente agregado")
	var count = get_ingredient_count()
	
	if count < get_max_ingredients():
		var type = ingredient.type
		ingredient_array.append(type)
		
		var sprite: TextureRect = icon_container.get_child(count + 1)
		sprite.visible = true
		
		Debug.log(ingredient_array)
	
	
