class_name FermentationJarInteractable
extends Interactable

enum JarType { INDOOR, OUTDOOR_SUN }

@export var jar_type: JarType = JarType.INDOOR
@export var jar_id: StringName = &"jar_1"

var content_item_id: StringName = &""
var content_amount: int = 0
var fermentation_days: int = 0
var current_quality_tier: int = 0

var _quality_tiers: Array[Dictionary] = [
	{"name": &"普通", "quality": 10},
	{"name": &"优质", "quality": 16},
	{"name": &"珍藏", "quality": 22},
]


func _ready() -> void:
	super._ready()
	add_to_group("fermentation_jars")
	interaction_name = "发酵坛"
	interaction_hint = "[空格] 发酵坛"


func interact() -> void:
	super.interact()
	# Check unlock before opening the fermenter panel
	if not UnlockManager.check_and_warn(&"fermenter"):
		return
	var panel: Control = GameUI.get_panel("FermenterUI")
	if panel and panel.has_method("setup"):
		panel.setup(self)
		GameUI.open_panel(panel)


func place_content(item_id: StringName, amount: int) -> bool:
	if content_item_id != &"":
		return false
	if not InventoryManager.remove_item(item_id, amount):
		return false
	content_item_id = item_id
	content_amount = amount
	fermentation_days = 0
	current_quality_tier = 0
	return true


func process_daily_fermentation() -> void:
	if content_item_id == &"":
		return
	fermentation_days += 1
	if fermentation_days % 4 == 0 and current_quality_tier < _quality_tiers.size() - 1:
		current_quality_tier += 1


func collect() -> void:
	if content_item_id == &"":
		return
	InventoryManager.add_item(content_item_id, content_amount)
	content_item_id = &""
	content_amount = 0
	fermentation_days = 0
	current_quality_tier = 0


func get_current_quality() -> int:
	if current_quality_tier < _quality_tiers.size():
		return _quality_tiers[current_quality_tier]["quality"]
	return 0


func get_save_data() -> Dictionary:
	return {
		"content_id": String(content_item_id),
		"amount": content_amount,
		"fermentation_days": fermentation_days,
		"quality_tier": current_quality_tier,
	}


func load_save_data(data: Dictionary) -> void:
	content_item_id = StringName(data.get("content_id", ""))
	content_amount = data.get("amount", 0)
	fermentation_days = data.get("fermentation_days", 0)
	current_quality_tier = data.get("quality_tier", 0)
