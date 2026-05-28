extends Control

# Autoloads needed for animal purchases
# BarnData - for managing barn animals
# AnimalTemplates - for getting animal templates

@onready var tab_container: TabContainer = $PanelContainer/MarginContainer/VBoxContainer/TabContainer
@onready var buy_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/BuyTab/BuyList
@onready var buy_item_name: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/BuyTab/BuyDetail/BuyItemName
@onready var buy_item_price: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/BuyTab/BuyDetail/BuyItemPrice
@onready var buy_amount_spin: SpinBox = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/BuyTab/BuyDetail/BuyAmountSpin
@onready var buy_button: Button = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/BuyTab/BuyButton
@onready var sell_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/SellTab/SellList
@onready var sell_item_name: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/SellTab/SellDetail/SellItemName
@onready var sell_item_price: Label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/SellTab/SellDetail/SellItemPrice
@onready var sell_amount_spin: SpinBox = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/SellTab/SellDetail/SellAmountSpin
@onready var sell_button: Button = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/SellTab/SellButton
@onready var gold_label: Label = $PanelContainer/MarginContainer/VBoxContainer/GoldLabel
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton
@onready var category_option: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/BuyTab/CategoryOption

var _buy_items: Array[Dictionary] = []
var _sell_items: Array[Dictionary] = []
var _feedback_label: Label = null


func _ready() -> void:
	if buy_list:
		buy_list.item_selected.connect(_on_buy_selected)
	if buy_button:
		buy_button.pressed.connect(_on_buy_pressed)
	if sell_list:
		sell_list.item_selected.connect(_on_sell_selected)
	if sell_button:
		sell_button.pressed.connect(_on_sell_pressed)
	if close_button:
		close_button.pressed.connect(_on_close)
	if category_option:
		category_option.item_selected.connect(_on_category_selected)
		_populate_categories()
	visibility_changed.connect(_on_visibility_changed)
	EventBus.inventory_changed.connect(_on_inventory_changed)
	_create_feedback_label()
	_refresh_all()


func _on_inventory_changed() -> void:
	_refresh_all()


func _on_visibility_changed() -> void:
	if visible:
		# Use call_deferred to ensure the ItemList has processed the
		# visibility change before we populate it.  Without this delay,
		# Godot's ItemList may silently discard add_item() calls that
		# happen in the same frame the node transitions from hidden → visible.
		_refresh_all.call_deferred()


func _create_feedback_label() -> void:
	_feedback_label = Label.new()
	_feedback_label.name = "FeedbackLabel"
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override("font_size", 13)
	_feedback_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_feedback_label.add_theme_constant_override("outline_size", 2)
	_feedback_label.visible = false
	var vbox: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer
	vbox.add_child(_feedback_label)
	vbox.move_child(_feedback_label, vbox.get_child_count() - 2)


func _show_feedback(text: String, is_error: bool = false) -> void:
	if _feedback_label == null:
		return
	_feedback_label.text = text
	_feedback_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3) if is_error else Color(0.3, 1, 0.5))
	_feedback_label.visible = true
	var tween: Tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(_feedback_label, "visible", false, 0.0)


func _populate_categories() -> void:
	if category_option == null:
		return
	category_option.clear()
	category_option.add_item("全部")
	var categories: Dictionary = {}
	var all_items: Dictionary = InventoryManager._item_registry
	for id: StringName in all_items:
		var info: Dictionary = all_items[id]
		if info.get("buy_price", 0) > 0:
			categories[info.get("category", "")] = true
	for cat: StringName in categories:
		category_option.add_item(String(cat))


func _on_category_selected(_index: int) -> void:
	_populate_buy_list()


func _refresh_all() -> void:
	_populate_categories()
	# Reset category selection to "全部" so all purchasable items are shown
	if category_option:
		category_option.select(0)
	_populate_buy_list()
	_populate_sell_list()
	_update_gold_display()


func _populate_buy_list() -> void:
	if buy_list == null:
		return
	buy_list.clear()
	_buy_items.clear()
	var selected_category: String = ""
	if category_option and category_option.get_selected_id() > 0:
		selected_category = category_option.get_item_text(category_option.selected)
	var all_items: Dictionary = InventoryManager._item_registry
	for id: StringName in all_items:
		var info: Dictionary = all_items[id]
		if info.get("buy_price", 0) > 0:
			if selected_category != "" and String(info.get("category", "")) != selected_category:
				continue
			_buy_items.append(info)
			# For animal items, show additional info like barn capacity
			var item_text: String = ""
			if info.get("category", "") == &"动物":
				item_text = "%s (%d文) [送至畜棚]" % [info.get("name", ""), info.get("buy_price", 0)]
			else:
				item_text = "%s (%d文)" % [info.get("name", ""), info.get("buy_price", 0)]
			buy_list.add_item(item_text)
	_clear_buy_detail()


func _populate_sell_list() -> void:
	if sell_list == null:
		return
	sell_list.clear()
	_sell_items.clear()
	if InventoryManager.items.is_empty():
		_clear_sell_detail()
		return
	for i: int in InventoryManager.inventory_size:
		var item: Dictionary = InventoryManager.items[i]
		if item.get("id", &"") == &"":
			continue
		var info: Dictionary = InventoryManager.get_item_info(item["id"])
		if info.is_empty():
			continue
		_sell_items.append({"slot": i, "info": info, "amount": item["amount"]})
		sell_list.add_item("%s x%d (%d文)" % [info.get("name", ""), item["amount"], info.get("sell_price", 0)])
	_clear_sell_detail()


func _on_buy_selected(index: int) -> void:
	if index < 0 or index >= _buy_items.size():
		return
	var info: Dictionary = _buy_items[index]
	if buy_item_name:
		buy_item_name.text = str(info.get("name", ""))
	if buy_item_price:
		buy_item_price.text = "%d文/个" % info.get("buy_price", 0)
	if buy_amount_spin:
		buy_amount_spin.value = 1
		buy_amount_spin.max_value = 99


func _on_sell_selected(index: int) -> void:
	if index < 0 or index >= _sell_items.size():
		return
	var entry: Dictionary = _sell_items[index]
	var info: Dictionary = entry.get("info", {})
	if sell_item_name:
		sell_item_name.text = str(info.get("name", ""))
	if sell_item_price:
		sell_item_price.text = "%d文/个" % info.get("sell_price", 0)
	if sell_amount_spin:
		sell_amount_spin.value = 1
		sell_amount_spin.max_value = entry.get("amount", 1)


func _on_buy_pressed() -> void:
	if buy_list == null:
		return
	var indices: Array = buy_list.get_selected_items()
	if indices.is_empty():
		_show_feedback("请先选择商品", true)
		return
	var index: int = indices[0]
	if index < 0 or index >= _buy_items.size():
		return
	var info: Dictionary = _buy_items[index]
	var price: int = info.get("buy_price", 0)
	var amount: int = int(buy_amount_spin.value) if buy_amount_spin else 1
	var total_cost: int = price * amount
	if PlayerData.gold < total_cost:
		_show_feedback("金币不足! 需要%d金" % total_cost, true)
		return
	var item_id: StringName = info.get("id", &"")
	var item_category: StringName = info.get("category", &"")
	
	# Special handling for animal purchases
	if item_category == &"动物":
		_handle_animal_purchase(info, amount, total_cost)
		return
	
	# Normal item purchase flow
	print("ShopUI: Buying item ", item_id, " x", amount)
	var leftover: int = InventoryManager.add_item(item_id, amount, true)
	var actually_bought: int = amount - leftover
	print("ShopUI: Actually bought ", actually_bought, ", leftover: ", leftover)
	if actually_bought > 0:
		PlayerData.gold -= price * actually_bought
		_show_feedback("购入 %s x%d" % [info.get("name", ""), actually_bought])
	else:
		_show_feedback("背包已满!", true)
	
	# Ensure inventory panel is updated after purchase
	# Emit the signal again to make sure all listeners receive it
	EventBus.inventory_changed.emit()
	
	_refresh_all()


func _handle_animal_purchase(info: Dictionary, amount: int, total_cost: int) -> void:
	var item_id: StringName = info.get("id", &"")
	var price: int = info.get("buy_price", 0)
	
	# Check if barn has room for the animal (babies cost 0.5 space)
	if not BarnData.has_room(true):
		_show_feedback("畜棚已满，无法购买更多动物", true)
		return
	
	# Determine which animal template to use based on the item id
	var template: Dictionary = {}
	match item_id:
		&"BabyPig":
			template = AnimalTemplates.baby_pig()
		&"BabyChicken":
			template = AnimalTemplates.baby_chicken()
		_:
			_show_feedback("未知的动物类型", true)
			return
	
	# Add animal to barn
	if not BarnData.add_animal(template):
		_show_feedback("畜棚已满，无法购买更多动物", true)
		return
	
	# Deduct gold from PlayerData.gold
	PlayerData.gold -= price
	
	# Show notification
	var animal_name: String = info.get("name", "")
	_show_feedback("%s已送至畜棚" % animal_name)
	
	# Refresh the UI
	_refresh_all()
	
	# Update gold display
	_update_gold_display()


func _on_sell_pressed() -> void:
	if sell_list == null:
		return
	var indices: Array = sell_list.get_selected_items()
	if indices.is_empty():
		_show_feedback("请先选择物品", true)
		return
	var index: int = indices[0]
	if index < 0 or index >= _sell_items.size():
		return
	var entry: Dictionary = _sell_items[index]
	var info: Dictionary = entry.get("info", {})
	var amount: int = int(sell_amount_spin.value) if sell_amount_spin else 1
	var item_id: StringName = info.get("id", &"")
	var sell_price: int = info.get("sell_price", 0)
	if InventoryManager.remove_item(item_id, amount):
		PlayerData.gold += sell_price * amount
		_show_feedback("售出 %s x%d 获得%d金" % [info.get("name", ""), amount, sell_price * amount])
	_refresh_all()


func _on_close() -> void:
	GameUI.close_panel()


func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "金币: %d" % PlayerData.gold


func _clear_buy_detail() -> void:
	if buy_item_name:
		buy_item_name.text = ""
	if buy_item_price:
		buy_item_price.text = ""
	if buy_amount_spin:
		buy_amount_spin.value = 1


func _clear_sell_detail() -> void:
	if sell_item_name:
		sell_item_name.text = ""
	if sell_item_price:
		sell_item_price.text = ""
	if sell_amount_spin:
		sell_amount_spin.value = 1
