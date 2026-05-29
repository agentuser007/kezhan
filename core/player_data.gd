extends Node

enum Attribute {
	STRENGTH,
	ENDURANCE,
	SPIRITUALITY,
	FOCUS,
	PHYSIQUE,
	ENERGY,
	TENACITY,
	AGILITY,
	VITALITY,
	SPIRIT_POWER
}

const ATTRIBUTE_NAMES: Dictionary = {
	Attribute.STRENGTH: &"力量",
	Attribute.ENDURANCE: &"耐力",
	Attribute.SPIRITUALITY: &"灵性",
	Attribute.FOCUS: &"专注",
	Attribute.PHYSIQUE: &"体能",
	Attribute.ENERGY: &"精力",
	Attribute.TENACITY: &"韧性",
	Attribute.AGILITY: &"敏捷",
	Attribute.VITALITY: &"活力",
	Attribute.SPIRIT_POWER: &"灵力",
}

var attributes: Dictionary = {
	Attribute.STRENGTH: 0.0,
	Attribute.ENDURANCE: 0.0,
	Attribute.SPIRITUALITY: 0.0,
	Attribute.FOCUS: 0.0,
	Attribute.PHYSIQUE: 0.0,
	Attribute.ENERGY: 0.0,
	Attribute.TENACITY: 0.0,
	Attribute.AGILITY: 0.0,
	Attribute.VITALITY: 0.0,
	Attribute.SPIRIT_POWER: 0.0,
}

var attribute_levels: Dictionary = {
	Attribute.STRENGTH: 1,
	Attribute.ENDURANCE: 1,
	Attribute.SPIRITUALITY: 1,
	Attribute.FOCUS: 1,
	Attribute.PHYSIQUE: 1,
	Attribute.ENERGY: 1,
	Attribute.TENACITY: 1,
	Attribute.AGILITY: 1,
	Attribute.VITALITY: 1,
	Attribute.SPIRIT_POWER: 1,
}

const XP_PER_LEVEL: float = 100.0

var max_hp: int = 100
var current_hp: int = 100
var max_stamina: int = 50
var current_stamina: int = 50
var max_mana: int = 30
var current_mana: int = 30
var max_sanity: int = 100
var current_sanity: int = 100
var max_weight: int = 100
var current_weight: int = 0

var farming_level: int = 1
var farming_mastery: int = 1
var farming_xp: float = 0.0
var ranching_level: int = 1
var ranching_mastery: int = 1
var ranching_xp: float = 0.0
var cooking_level: int = 1
var cooking_mastery: int = 1
var cooking_xp: float = 0.0

var morning_training: Dictionary = {
	&"气力": false,
	&"冥想": false,
	&"体力": false,
	&"敏捷": false,
	&"武学": false,
}
var morning_training_wushu_selection: StringName = &""
var consecutive_no_eat_days: int = 0

var gold: int = 1000
var inn_reputation: float = 0.0
var inn_level: int = 1

var player_position: Vector2 = Vector2.ZERO
var current_scene: String = ""
var facing_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	EventBus.new_day_started.connect(_on_new_day_started)


func add_attribute_xp(attr: Attribute, amount: float) -> void:
	if consecutive_no_eat_days > 2:
		amount *= 0.1
	attributes[attr] += amount
	while attributes[attr] >= attribute_levels[attr] * XP_PER_LEVEL:
		attributes[attr] -= attribute_levels[attr] * XP_PER_LEVEL
		attribute_levels[attr] += 1
		_on_attribute_level_up(attr)


func _on_attribute_level_up(attr: Attribute) -> void:
	var attr_name: StringName = ATTRIBUTE_NAMES.get(attr, &"属性")
	var msg: String = "%s 提升至 %d 级!" % [attr_name, attribute_levels[attr]]
	call_deferred("_display_level_up_fx", msg)

	match attr:
		Attribute.STRENGTH:
			pass
		Attribute.ENDURANCE:
			pass
		Attribute.ENERGY:
			max_hp += 10
			current_hp = max_hp
		Attribute.PHYSIQUE:
			max_weight += 20
		Attribute.TENACITY:
			max_sanity += 10
			current_sanity = max_sanity
		Attribute.FOCUS:
			pass
		Attribute.SPIRITUALITY:
			pass


func apply_food(food_category: StringName, quality: float = 1.0) -> void:
	var main_attr: Attribute
	var sub_attr: Attribute = Attribute.ENERGY
	var weak_attrs: Array[Attribute] = []
	var main_xp: float = 20.0 * quality
	var sub_xp: float = 10.0 * quality
	var weak_xp: float = 5.0 * quality

	match food_category:
		&"肉类":
			main_attr = Attribute.STRENGTH
			sub_attr = Attribute.ENDURANCE
		&"鱼类":
			main_attr = Attribute.AGILITY
			weak_attrs = [Attribute.STRENGTH, Attribute.ENDURANCE]
		&"酒类":
			main_attr = Attribute.ENDURANCE
			sub_attr = Attribute.STRENGTH
		&"主食":
			main_attr = Attribute.ENERGY
			sub_attr = Attribute.VITALITY
		&"菜类":
			main_attr = Attribute.SPIRIT_POWER
			sub_attr = Attribute.FOCUS
		&"蛋类":
			main_attr = Attribute.AGILITY
			weak_attrs = [Attribute.SPIRIT_POWER, Attribute.FOCUS]
		&"饮品":
			main_attr = Attribute.FOCUS
			sub_attr = Attribute.SPIRIT_POWER
		&"甜点":
			main_attr = Attribute.VITALITY
			sub_attr = Attribute.ENERGY
			weak_attrs = [Attribute.AGILITY]
		&"果类":
			main_attr = Attribute.ENERGY
			sub_attr = Attribute.AGILITY
		&"坚果类":
			main_attr = Attribute.AGILITY
			weak_attrs = [Attribute.VITALITY, Attribute.ENERGY]
		_:
			return

	add_attribute_xp(main_attr, main_xp)
	add_attribute_xp(sub_attr, sub_xp)
	for weak_attr: Attribute in weak_attrs:
		add_attribute_xp(weak_attr, weak_xp)

	consecutive_no_eat_days = 0


func add_farming_xp(amount: float) -> void:
	farming_xp += amount
	while farming_xp >= _xp_for_skill_level(farming_level):
		farming_xp -= _xp_for_skill_level(farming_level)
		farming_level += 1
		call_deferred("_display_level_up_fx", "农事 提升至 %d 级!" % farming_level)
	EventBus.inventory_changed.emit()


func add_ranching_xp(amount: float) -> void:
	ranching_xp += amount
	while ranching_xp >= _xp_for_skill_level(ranching_level):
		ranching_xp -= _xp_for_skill_level(ranching_level)
		ranching_level += 1
		call_deferred("_display_level_up_fx", "畜牧 提升至 %d 级!" % ranching_level)
	EventBus.inventory_changed.emit()


func add_cooking_xp(amount: float) -> void:
	cooking_xp += amount
	while cooking_xp >= _xp_for_skill_level(cooking_level):
		cooking_xp -= _xp_for_skill_level(cooking_level)
		cooking_level += 1
		call_deferred("_display_level_up_fx", "烹饪 提升至 %d 级!" % cooking_level)
	EventBus.inventory_changed.emit()


func _xp_for_skill_level(level: int) -> float:
	return level * 50.0


func get_farming_yield_multiplier() -> float:
	match farming_mastery:
		1:
			return 1.0
		2:
			return 1.15
		3:
			return 1.30
		4:
			return 1.50
		_:
			return 1.0


func get_farming_pest_chance() -> float:
	match farming_mastery:
		1:
			return 0.20
		2:
			return 0.15
		3:
			return 0.10
		4:
			return 0.05
		_:
			return 0.20


func get_farming_interact_time() -> float:
	match farming_mastery:
		1:
			return 3.0
		2:
			return 2.0
		3:
			return 1.0
		4:
			return 0.0
		_:
			return 3.0


func _on_new_day_started(_day: int) -> void:
	if TimeManager.meals_eaten_today == 0:
		consecutive_no_eat_days += 1
	else:
		consecutive_no_eat_days = 0

	var trained_items: Array[String] = []
	var training_keys: Array = morning_training.keys()
	for key: StringName in training_keys:
		if morning_training[key]:
			match key:
				&"气力":
					add_attribute_xp(Attribute.STRENGTH, 5.0)
					trained_items.append("力量 +5 XP")
				&"冥想":
					add_attribute_xp(Attribute.SPIRITUALITY, 5.0)
					trained_items.append("灵性 +5 XP")
				&"体力":
					add_attribute_xp(Attribute.ENDURANCE, 5.0)
					trained_items.append("耐力 +5 XP")
				&"敏捷":
					add_attribute_xp(Attribute.AGILITY, 5.0)
					trained_items.append("敏捷 +5 XP")
				&"武学":
					add_attribute_xp(Attribute.STRENGTH, 3.0)
					add_attribute_xp(Attribute.AGILITY, 3.0)
					var wushu_sel: String = String(morning_training_wushu_selection) if not morning_training_wushu_selection.is_empty() else "武学"
					trained_items.append("%s +3 XP" % wushu_sel)

	if trained_items.size() > 0:
		call_deferred("_display_morning_training_fx", trained_items)


func take_action(stamina_cost: int = 1) -> bool:
	if current_stamina < stamina_cost:
		return false
	current_stamina -= stamina_cost
	EventBus.player_stats_changed.emit()
	return true


func reset_stamina() -> void:
	current_stamina = max_stamina
	EventBus.player_stats_changed.emit()


func heal_hp(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	EventBus.player_stats_changed.emit()


func take_damage_hp(amount: int) -> void:
	current_hp = maxi(current_hp - amount, 0)
	EventBus.player_stats_changed.emit()


func get_save_data() -> Dictionary:
	return {
		"attributes": attributes.duplicate(),
		"attribute_levels": attribute_levels.duplicate(),
		"max_hp": max_hp,
		"current_hp": current_hp,
		"max_stamina": max_stamina,
		"current_stamina": current_stamina,
		"max_mana": max_mana,
		"current_mana": current_mana,
		"max_sanity": max_sanity,
		"current_sanity": current_sanity,
		"max_weight": max_weight,
		"current_weight": current_weight,
		"farming_level": farming_level,
		"farming_mastery": farming_mastery,
		"farming_xp": farming_xp,
		"ranching_level": ranching_level,
		"ranching_mastery": ranching_mastery,
		"ranching_xp": ranching_xp,
		"cooking_level": cooking_level,
		"cooking_mastery": cooking_mastery,
		"cooking_xp": cooking_xp,
		"morning_training": morning_training.duplicate(),
		"morning_training_wushu": morning_training_wushu_selection,
		"consecutive_no_eat_days": consecutive_no_eat_days,
		"gold": gold,
		"inn_reputation": inn_reputation,
		"inn_level": inn_level,
		"player_position": {"x": player_position.x, "y": player_position.y},
		"current_scene": current_scene,
		"facing_direction": {"x": facing_direction.x, "y": facing_direction.y},
	}


func load_save_data(data: Dictionary) -> void:
	var attrs_data: Dictionary = data.get("attributes", {})
	for key: int in attrs_data:
		attributes[key] = attrs_data[key]
	var levels_data: Dictionary = data.get("attribute_levels", {})
	for key: int in levels_data:
		attribute_levels[key] = levels_data[key]
	max_hp = data.get("max_hp", 100)
	current_hp = data.get("current_hp", 100)
	max_stamina = data.get("max_stamina", 50)
	current_stamina = data.get("current_stamina", 50)
	max_mana = data.get("max_mana", 30)
	current_mana = data.get("current_mana", 30)
	max_sanity = data.get("max_sanity", 100)
	current_sanity = data.get("current_sanity", 100)
	max_weight = data.get("max_weight", 100)
	current_weight = data.get("current_weight", 0)
	farming_level = data.get("farming_level", 1)
	farming_mastery = data.get("farming_mastery", 1)
	farming_xp = data.get("farming_xp", 0.0)
	ranching_level = data.get("ranching_level", 1)
	ranching_mastery = data.get("ranching_mastery", 1)
	ranching_xp = data.get("ranching_xp", 0.0)
	cooking_level = data.get("cooking_level", 1)
	cooking_mastery = data.get("cooking_mastery", 1)
	cooking_xp = data.get("cooking_xp", 0.0)
	var training_data: Dictionary = data.get("morning_training", {})
	for key: StringName in training_data:
		morning_training[key] = training_data[key]
	morning_training_wushu_selection = data.get("morning_training_wushu", &"")
	consecutive_no_eat_days = data.get("consecutive_no_eat_days", 0)
	gold = data.get("gold", 10)
	inn_reputation = data.get("inn_reputation", 0.0)
	inn_level = data.get("inn_level", 1)
	var pos_data: Dictionary = data.get("player_position", {"x": 0, "y": 0})
	player_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
	current_scene = data.get("current_scene", "")
	var dir_data: Dictionary = data.get("facing_direction", {"x": 0, "y": 1})
	facing_direction = Vector2(dir_data.get("x", 0), dir_data.get("y", 1))


func _display_morning_training_fx(items: Array) -> void:
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.is_empty():
		return
	var player = player_nodes[0]
	if player and player.has_method("show_training_text"):
		player.show_training_text(items)


func _display_level_up_fx(msg: String) -> void:
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.is_empty():
		return
	var player = player_nodes[0]
	if player and player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🏆 " + msg, Color(0.3, 1.0, 0.5))
