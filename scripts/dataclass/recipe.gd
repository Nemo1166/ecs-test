class_name Recipe extends Resource

@export var id: int = 0
@export var name: String = ""
@export var category: Category = Category.OTHERS
@export var description: String = ""
@export var ingredients: Dictionary = {}
@export var results: Dictionary = {}
@export var duration: int = 6


enum Category {
	RAW_MATERIALS,
	INTERMEDIATE_PRODUCTS,
	CONSUMABLES,
	TOOLS,
	WEAPONS,
	ARMOR,
	VEHICLES,
	STRUCTURES,
	OTHERS
}