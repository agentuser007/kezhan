class_name RecipeData
extends Resource

enum SlotType { MAIN_INGREDIENT, SUB_INGREDIENT, SEASONING, FUEL }

@export var recipe_id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var tags: Array[StringName] = []
@export var main_ingredients: Dictionary = {}
@export var sub_ingredients: Dictionary = {}
@export var seasonings: Dictionary = {}
@export var fuel: Dictionary = {}
@export var output_item_id: StringName = &""
@export var output_amount: int = 1
@export var base_quality: int = 14
@export var cooking_time_seconds: float = 30.0
@export var required_cooking_level: int = 1
@export var cooking_station_type: StringName = &"stove"
