extends Node

var items: Array[Dictionary] = []
var hotbar_size: int = 10
var inventory_size: int = 30
var selected_hotbar_slot: int = 0

var _item_registry: Dictionary = {}
var _icon_map: Dictionary = {}
var _recipe_registry: Dictionary = {}


func _ready() -> void:
	_register_icons()
	_register_items()
	_register_recipes()


func _register_icons() -> void:
	var base: String = "res://ui/inventory/tools and items/"
	_icon_map = {
		&"WateringCan": base + "Watering Can.png",
		&"Hoe": base + "Hoe.png",
		&"Axe": base + "Axe.png",
		&"Hammer": base + "Hammer.png",
		&"Sickle": base + "Sickle.png",
		&"Gold": base + "Gold.png",
		&"TurnipSeeds": base + "TurnipSeeds.png",
		&"StrawberrySeeds": base + "StrawberrySeeds.png",
		&"EggplantSeeds": base + "EggplantSeeds.png",
		&"GingerSeeds": base + "EggplantSeeds.png",
		&"ChiliSeeds": base + "EggplantSeeds.png",
		&"WheatSeeds": base + "TurnipSeeds.png",
		&"GlutinousRiceSeeds": base + "TurnipSeeds.png",
		&"ScallionSeeds": base + "StrawberrySeeds.png",
		&"TomatoSeeds": base + "EggplantSeeds.png",
		&"MelonSeeds": base + "StrawberrySeeds.png",
		&"PotatoSeeds": base + "TurnipSeeds.png",
		&"CornSeeds": base + "TurnipSeeds.png",
		&"Turnip": base + "Turnip.png",
		&"Strawberry": base + "Strawberry.png",
		&"Eggplant": base + "Eggplant.png",
		&"Scallion": base + "Turnip.png",
		&"Ginger": base + "Turnip.png",
		&"Chili": base + "Eggplant.png",
		&"Wheat": base + "Turnip.png",
		&"SweetPotato": base + "Turnip.png",
		&"Sugarcane": base + "Strawberry.png",
		&"GlutinousRice": base + "Turnip.png",
		&"Tomato": base + "Eggplant.png",
		&"Melon": base + "Strawberry.png",
		&"Potato": base + "Turnip.png",
		&"Corn": base + "Turnip.png",
		&"Pork": base + "Pork.png",
		&"Chicken": base + "Eggplant.png",
		&"Duck": base + "Eggplant.png",
		&"Beef": base + "Eggplant.png",
		&"Mutton": base + "Eggplant.png",
		&"Egg": base + "Strawberry.png",
		&"DuckEgg": base + "Strawberry.png",
		&"Milk": base + "Strawberry.png",
		&"GoatMilk": base + "Strawberry.png",
		&"Firewood": base + "Axe.png",
		&"Stone": base + "Hammer.png",
		&"Fertilizer": base + "Hoe.png",
		&"PestRemedy": base + "Sickle.png",
		&"WeedingSickle": base + "Sickle.png",
		&"HuadiaoWineSoup": base + "Strawberry.png",
		&"HuadiaoOriginal": base + "Strawberry.png",
		&"HuadiaoWine": base + "Strawberry.png",
		&"SoySauceSoup": base + "Turnip.png",
		&"SoySauce": base + "Turnip.png",
		&"PorkBroth": base + "Eggplant.png",
		&"Spice": base + "Eggplant.png",
		&"Salt": base + "Turnip.png",
		&"Soybean": base + "Turnip.png",
		&"Flour": base + "Turnip.png",
		&"Koji": base + "Turnip.png",
		&"SweetWineKoji": base + "Turnip.png",
		&"DriedScallop": base + "Eggplant.png",
		&"PigBone": base + "Eggplant.png",
		&"ToughPork": base + "Eggplant.png",
		&"PigSkin": base + "Eggplant.png",
		&"SucklingPig": base + "Eggplant.png",
		&"PoultryFeed": base + "Hoe.png",
		&"PigFeed": base + "Hoe.png",
		&"BabyPig": "res://resources/icons/animals/baby_pig.png",
		&"BabyChicken": "res://resources/icons/animals/baby_chicken.png",
		&"DishHongshaorou": base + "DishHongshaorou.png",
		&"DishQingzhengyu": base + "Strawberry.png",
		&"DishHuadiaotang": base + "Strawberry.png",
		&"DishHongshaopaigu": base + "Eggplant.png",
		&"DishJiangyouDoufu": base + "Turnip.png",
		&"DishZhuti": base + "Eggplant.png",
		&"DishGanbeiDunpaigu": base + "Eggplant.png",
	}


func get_item_icon(id: StringName) -> Texture2D:
	var path: String = _icon_map.get(id, "")
	if path.is_empty():
		return null
	return load(path) as Texture2D


func _register_items() -> void:
	_register_item(&"WateringCan", &"浇水壶", &"工具", 1, 0, 10)
	_register_item(&"Hoe", &"锄头", &"工具", 1, 0, 15)
	_register_item(&"Axe", &"斧头", &"工具", 1, 0, 20)
	_register_item(&"Hammer", &"锤子", &"工具", 1, 0, 25)
	_register_item(&"Sickle", &"镰刀", &"工具", 1, 0, 30)
	_register_item(&"Gold", &"金币", &"货币", 9999, 1, 0)
	_register_item(&"TurnipSeeds", &"萝卜种子", &"种子", 99, 5, 10)
	_register_item(&"StrawberrySeeds", &"草莓种子", &"种子", 99, 10, 15)
	_register_item(&"EggplantSeeds", &"茄子种子", &"种子", 99, 20, 25)
	_register_item(&"ScallionSeeds", &"葱种子", &"种子", 99, 8, 12)
	_register_item(&"GingerSeeds", &"姜种子", &"种子", 99, 8, 12)
	_register_item(&"ChiliSeeds", &"辣椒种子", &"种子", 99, 12, 18)
	_register_item(&"WheatSeeds", &"小麦种子", &"种子", 99, 6, 10)
	_register_item(&"SweetPotatoSeeds", &"红薯种子", &"种子", 99, 10, 15)
	_register_item(&"SugarcaneSeeds", &"甘蔗种子", &"种子", 99, 15, 20)
	_register_item(&"GlutinousRiceSeeds", &"糯米种子", &"种子", 99, 8, 12)
	_register_item(&"TomatoSeeds", &"番茄种子", &"种子", 99, 15, 20)
	_register_item(&"MelonSeeds", &"瓜种子", &"种子", 99, 25, 30)
	_register_item(&"PotatoSeeds", &"土豆种子", &"种子", 99, 12, 15)
	_register_item(&"CornSeeds", &"玉米种子", &"种子", 99, 10, 12)
	_register_item(&"Turnip", &"萝卜", &"蔬菜", 99, 10, 0)
	_register_item(&"Strawberry", &"草莓", &"水果", 99, 20, 0)
	_register_item(&"Eggplant", &"茄子", &"蔬菜", 99, 45, 0)
	_register_item(&"Scallion", &"葱", &"蔬菜", 99, 5, 0)
	_register_item(&"Ginger", &"姜", &"蔬菜", 99, 5, 0)
	_register_item(&"Chili", &"辣椒", &"蔬菜", 99, 15, 0)
	_register_item(&"Wheat", &"小麦", &"主食", 99, 8, 0)
	_register_item(&"SweetPotato", &"红薯", &"主食", 99, 12, 0)
	_register_item(&"Sugarcane", &"甘蔗", &"水果", 99, 18, 0)
	_register_item(&"GlutinousRice", &"糯米", &"主食", 99, 10, 0)
	_register_item(&"Tomato", &"番茄", &"蔬菜", 99, 30, 0)
	_register_item(&"Melon", &"瓜", &"水果", 99, 50, 0)
	_register_item(&"Potato", &"土豆", &"主食", 99, 15, 0)
	_register_item(&"Corn", &"玉米", &"主食", 99, 12, 0)
	_register_item(&"Pork", &"猪肉", &"肉类", 99, 30, 45)
	_register_item(&"Chicken", &"鸡肉", &"肉类", 99, 25, 38)
	_register_item(&"Duck", &"鸭肉", &"肉类", 99, 28, 0)
	_register_item(&"Beef", &"牛肉", &"肉类", 99, 50, 0)
	_register_item(&"Mutton", &"羊肉", &"肉类", 99, 35, 0)
	_register_item(&"Egg", &"鸡蛋", &"蛋类", 99, 8, 12)
	_register_item(&"DuckEgg", &"鸭蛋", &"蛋类", 99, 10, 0)
	_register_item(&"Milk", &"牛奶", &"饮品", 99, 15, 0)
	_register_item(&"GoatMilk", &"羊奶", &"饮品", 99, 18, 0)
	_register_item(&"Firewood", &"柴火", &"杂项", 99, 3, 5)
	_register_item(&"Stone", &"石头", &"杂项", 99, 2, 0)
	_register_item(&"Fertilizer", &"肥料", &"杂项", 99, 10, 15)
	_register_item(&"PestRemedy", &"除虫药", &"杂项", 99, 12, 18)
	_register_item(&"WeedingSickle", &"除草镰", &"工具", 99, 8, 0)
	_register_item(&"HuadiaoWineSoup", &"花雕酒汤", &"酒类", 99, 25, 0)
	_register_item(&"HuadiaoOriginal", &"花雕原浆", &"酒类", 99, 40, 0)
	_register_item(&"HuadiaoWine", &"花雕酒", &"酒类", 99, 50, 0)
	_register_item(&"SoySauceSoup", &"酱油原汤", &"调料", 99, 20, 0)
	_register_item(&"SoySauce", &"酱油", &"调料", 99, 30, 0)
	_register_item(&"PorkBroth", &"猪高汤", &"调料", 99, 35, 0)
	_register_item(&"Spice", &"香料", &"调料", 99, 15, 20)
	_register_item(&"Salt", &"盐", &"调料", 99, 5, 8)
	_register_item(&"Soybean", &"黄豆", &"主食", 99, 8, 0)
	_register_item(&"Flour", &"面粉", &"主食", 99, 6, 0)
	_register_item(&"Koji", &"酱曲", &"调料", 99, 12, 18)
	_register_item(&"SweetWineKoji", &"甜酒曲", &"调料", 99, 10, 15)
	_register_item(&"DriedScallop", &"干贝", &"菜类", 99, 40, 0)
	_register_item(&"PigBone", &"猪大骨", &"肉类", 99, 20, 0)
	_register_item(&"ToughPork", &"柴猪肉", &"肉类", 99, 10, 0)
	_register_item(&"PigSkin", &"猪皮", &"杂项", 99, 15, 0)
	_register_item(&"SucklingPig", &"乳猪肉", &"肉类", 99, 80, 0)
	_register_item(&"PoultryFeed", &"禽类饲料", &"杂项", 99, 5, 8)
	_register_item(&"PigFeed", &"猪饲料", &"杂项", 99, 8, 12)
	# Animals (livestock)
	_register_item(&"BabyPig", &"小猪", &"动物", 1, 0, 200)
	_register_item(&"BabyChicken", &"小鸡", &"动物", 1, 0, 80)
	# Cooked dishes
	_register_item(&"DishHongshaorou", &"红烧肉", &"肉类", 99, 60, 0)
	_register_item(&"DishQingzhengyu", &"清蒸鱼", &"肉类", 99, 50, 0)
	_register_item(&"DishHuadiaotang", &"花雕酒汤", &"酒类", 99, 40, 0)
	_register_item(&"DishHongshaopaigu", &"红烧排骨", &"肉类", 99, 70, 0)
	_register_item(&"DishJiangyouDoufu", &"酱油豆腐", &"菜类", 99, 35, 0)
	_register_item(&"DishZhuti", &"猪蹄", &"肉类", 99, 80, 0)
	_register_item(&"DishGanbeiDunpaigu", &"干贝炖排骨", &"肉类", 99, 100, 0)


func _register_item(
	id: StringName,
	display_name: StringName,
	category: StringName,
	max_stack: int,
	sell_price: int,
	buy_price: int
) -> void:
	_item_registry[id] = {
		"id": id,
		"name": display_name,
		"category": category,
		"max_stack": max_stack,
		"sell_price": sell_price,
		"buy_price": buy_price,
	}


# ── Recipe Registry ──────────────────────────────────────────────────────────


func _register_recipes() -> void:
	## Register all recipes with ingredients, output, and level requirements.
	_recipes_register_basic()
	_recipes_register_intermediate()
	_recipes_register_advanced()


func _recipes_register_basic() -> void:
	## Cooking level 1 recipes.
	_register_recipe(
		&"hongshaorou",
		&"红烧肉",
		"鲜咸微辣的炖肉，客栈招牌菜之一。",
		1,
		[
			{"id": &"Pork", "name": "猪肉", "amount": 2},
			{"id": &"SoySauce", "name": "酱油", "amount": 1},
			{"id": &"Spice", "name": "香料", "amount": 1},
			{"id": &"Salt", "name": "盐", "amount": 1},
			{"id": &"Firewood", "name": "柴火", "amount": 1}
		],
		&"DishHongshaorou",
		1,
		14
	)
	_register_recipe(
		&"qingzhengyu",
		&"清蒸鱼",
		"鲜嫩可口的蒸鱼。",
		1,
		[
			{"id": &"Ginger", "name": "姜", "amount": 1},
			{"id": &"Scallion", "name": "葱", "amount": 1},
			{"id": &"SoySauceSoup", "name": "酱油原汤", "amount": 1},
			{"id": &"Salt", "name": "盐", "amount": 1},
			{"id": &"Firewood", "name": "柴火", "amount": 1}
		],
		&"DishQingzhengyu",
		1,
		16
	)
	_register_recipe(
		&"huadiaotang",
		&"花雕酒汤",
		"温润的花雕酒汤，暖身提神。",
		1,
		[
			{"id": &"GlutinousRice", "name": "糯米", "amount": 2},
			{"id": &"SweetWineKoji", "name": "甜酒曲", "amount": 1},
			{"id": &"Firewood", "name": "柴火", "amount": 1}
		],
		&"DishHuadiaotang",
		1,
		12
	)


func _recipes_register_intermediate() -> void:
	## Cooking level 2 recipes.
	_register_recipe(
		&"hongshaopaigu",
		&"红烧排骨",
		"酱香浓郁的排骨，回味无穷。",
		2,
		[
			{"id": &"PigBone", "name": "猪大骨", "amount": 2},
			{"id": &"SoySauce", "name": "酱油", "amount": 1},
			{"id": &"Spice", "name": "香料", "amount": 1},
			{"id": &"Firewood", "name": "柴火", "amount": 2}
		],
		&"DishHongshaopaigu",
		1,
		18
	)
	_register_recipe(
		&"jiangyou_doufu",
		&"酱油豆腐",
		"家常豆腐，简单美味。",
		2,
		[
			{"id": &"Soybean", "name": "黄豆", "amount": 2},
			{"id": &"SoySauce", "name": "酱油", "amount": 1},
			{"id": &"Salt", "name": "盐", "amount": 1},
			{"id": &"Firewood", "name": "柴火", "amount": 1}
		],
		&"DishJiangyouDoufu",
		1,
		15
	)


func _recipes_register_advanced() -> void:
	## Cooking level 3+ recipes.
	_register_recipe(
		&"zhuti",
		&"猪蹄",
		"软糯Q弹的卤猪蹄。",
		3,
		[
			{"id": &"PigSkin", "name": "猪皮", "amount": 2},
			{"id": &"SoySauce", "name": "酱油", "amount": 2},
			{"id": &"Spice", "name": "香料", "amount": 2},
			{"id": &"Firewood", "name": "柴火", "amount": 2}
		],
		&"DishZhuti",
		1,
		22
	)
	_register_recipe(
		&"ganbei_dunpaigu",
		&"干贝炖排骨",
		"鲜美无比的干贝排骨汤。",
		3,
		[
			{"id": &"DriedScallop", "name": "干贝", "amount": 1},
			{"id": &"PigBone", "name": "猪大骨", "amount": 1},
			{"id": &"PorkBroth", "name": "猪高汤", "amount": 1},
			{"id": &"Salt", "name": "盐", "amount": 1},
			{"id": &"Firewood", "name": "柴火", "amount": 2}
		],
		&"DishGanbeiDunpaigu",
		1,
		24
	)


func _register_recipe(
	id: StringName,
	display_name: String,
	desc: String,
	required_level: int,
	ingredients: Array[Dictionary],
	output_id: StringName,
	output_amount: int,
	base_quality: int
) -> void:
	_recipe_registry[id] = {
		"id": id,
		"name": display_name,
		"description": desc,
		"required_cooking_level": required_level,
		"ingredients": ingredients,
		"output_id": output_id,
		"output_amount": output_amount,
		"base_quality": base_quality,
	}


func get_all_recipes() -> Array[Dictionary]:
	## Returns all registered recipes as an array of dictionaries.
	var result: Array[Dictionary] = []
	for key: StringName in _recipe_registry:
		result.append(_recipe_registry[key])
	return result


func get_unlocked_recipes() -> Array[Dictionary]:
	## Returns recipes the player has the cooking level to use.
	var result: Array[Dictionary] = []
	for key: StringName in _recipe_registry:
		var recipe: Dictionary = _recipe_registry[key]
		if recipe.get("required_cooking_level", 999) <= PlayerData.cooking_level:
			result.append(recipe)
	return result


func get_recipe(id: StringName) -> Dictionary:
	## Returns a single recipe by id, or empty dict if not found.
	return _recipe_registry.get(id, {})


func _initialize_starting_items() -> void:
	items.clear()
	for i in inventory_size + hotbar_size:
		items.append({"id": &"", "amount": 0})

	# Place tools directly into hotbar slots (indices 30-39)
	# Hotbar slot 0 = items[30], slot 1 = items[31], etc.
	var _hotbar_tools: Array[Dictionary] = [
		{"id": &"WateringCan", "amount": 1},
		{"id": &"Hoe", "amount": 1},
		{"id": &"Sickle", "amount": 1},
		{"id": &"Axe", "amount": 1},
		{"id": &"Hammer", "amount": 1},
	]
	for i: int in _hotbar_tools.size():
		items[inventory_size + i] = _hotbar_tools[i]

	# Consumable items fill inventory slots 0-N via add_item
	add_item(&"ScallionSeeds", 18)
	add_item(&"GingerSeeds", 12)
	add_item(&"ChiliSeeds", 12)
	add_item(&"WheatSeeds", 12)
	add_item(&"GlutinousRiceSeeds", 12)
	add_item(&"Pork", 10)
	add_item(&"Firewood", 10)
	add_item(&"Salt", 5)
	add_item(&"SoySauce", 3)
	add_item(&"HuadiaoWine", 2)
	add_item(&"Spice", 2)
	add_item(&"PorkBroth", 2)
	add_item(&"PoultryFeed", 10)
	add_item(&"PigFeed", 6)
	add_item(&"Gold", 1000)

	# Ensure hotbar display refreshes after direct slot assignment
	EventBus.inventory_changed.emit()


func get_item_info(id: StringName) -> Dictionary:
	if _item_registry.has(id):
		return _item_registry[id]
	return {}


func add_item(id: StringName, amount: int = 1, prioritize_hotbar: bool = true) -> int:
	print("InventoryManager: Adding item ", id, " x", amount)
	var remaining: int = amount
	var info: Dictionary = get_item_info(id)
	if info.is_empty():
		print("InventoryManager: Item info not found for ", id)
		return remaining
	var max_stack: int = info.get("max_stack", 1)
	print("InventoryManager: Max stack for ", id, " is ", max_stack)

	# Prioritize hotbar slots (indices 30-39) over backpack slots (indices 0-29) only if requested
	var search_order: Array[int] = []
	if prioritize_hotbar:
		for i in range(inventory_size, inventory_size + hotbar_size):
			search_order.append(i)
		for i in range(0, inventory_size):
			search_order.append(i)
	else:
		for i in range(0, inventory_size):
			search_order.append(i)
		for i in range(inventory_size, inventory_size + hotbar_size):
			search_order.append(i)

	for i in search_order:
		if remaining <= 0:
			break
		if items[i]["id"] == id:
			var can_add: int = mini(max_stack - items[i]["amount"], remaining)
			items[i]["amount"] += can_add
			print("InventoryManager: Added ", can_add, " to existing stack at index ", i)
			remaining -= can_add

	for i in search_order:
		if remaining <= 0:
			break
		if items[i]["id"] == &"" or items[i]["amount"] <= 0:
			var can_add: int = mini(max_stack, remaining)
			items[i] = {"id": id, "amount": can_add}
			print("InventoryManager: Created new stack at index ", i, " with ", can_add)
			remaining -= can_add

	print("InventoryManager: Finished adding item, remaining: ", remaining)
	EventBus.inventory_changed.emit()
	return remaining


func remove_item(id: StringName, amount: int = 1) -> bool:
	var available: int = get_amount(id)
	if available < amount:
		return false
	var remaining: int = amount
	for i in range(items.size() - 1, -1, -1):
		if remaining <= 0:
			break
		if items[i]["id"] == id:
			var to_remove: int = mini(items[i]["amount"], remaining)
			items[i]["amount"] -= to_remove
			remaining -= to_remove
			if items[i]["amount"] <= 0:
				items[i] = {"id": &"", "amount": 0}

	EventBus.inventory_changed.emit()
	return true


func get_amount(id: StringName) -> int:
	var total: int = 0
	for item: Dictionary in items:
		if item["id"] == id:
			total += item["amount"]
	return total


func has_item(id: StringName, amount: int = 1) -> bool:
	return get_amount(id) >= amount


func get_hotbar_item(slot: int) -> Dictionary:
	if slot < 0 or slot >= hotbar_size:
		return {"id": &"", "amount": 0}
	var idx: int = inventory_size + slot
	if idx >= items.size():
		return {"id": &"", "amount": 0}
	return items[idx]


func get_selected_item() -> Dictionary:
	return get_hotbar_item(selected_hotbar_slot)


func get_selected_item_id() -> StringName:
	var item: Dictionary = get_selected_item()
	return item.get("id", &"")


func select_hotbar_slot(slot: int) -> void:
	selected_hotbar_slot = clampi(slot, 0, hotbar_size - 1)
	EventBus.hotbar_selection_changed.emit(selected_hotbar_slot)


func move_item(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return
	if from_index < 0 or from_index >= items.size():
		return
	if to_index < 0 or to_index >= items.size():
		return
	var temp: Dictionary = items[from_index]
	items[from_index] = items[to_index]
	items[to_index] = temp
	EventBus.inventory_changed.emit()


func get_save_data() -> Array:
	var save_items: Array = []
	for item: Dictionary in items:
		save_items.append({"id": String(item["id"]), "amount": item["amount"]})
	return save_items


func load_save_data(data: Array) -> void:
	items.clear()
	for i in inventory_size + hotbar_size:
		if i < data.size():
			var d: Dictionary = data[i]
			items.append({"id": StringName(d.get("id", "")), "amount": d.get("amount", 0)})
		else:
			items.append({"id": &"", "amount": 0})
	EventBus.inventory_changed.emit()
