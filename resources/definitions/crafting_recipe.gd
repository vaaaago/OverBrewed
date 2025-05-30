class_name CraftingRecipe
extends Resource

@export var ingredients: Array[Item]
@export var output: Item

func can_craft(id_array: Array[int]) -> bool:
	var ig_ids: Array[int] = []
	for item in ingredients:
		ig_ids.append(item.ID)
	
	ig_ids.sort()
	id_array.sort()
	
	return id_array == ig_ids
