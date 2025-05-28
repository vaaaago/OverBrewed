class_name CraftingRecipe
extends Resource

@export var ingredients: Array[CraftingIngredient]
@export var output: CraftingIngredient

func _can_craft(inventory_list: Dictionary) -> bool:
	var valid = true
	
	return valid
