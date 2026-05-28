extends Control

## FermenterUI — Panel for interacting with a FermentationJar.
## Shows input slot, fermentation progress, quality tier, output preview, and action buttons.

@onready var content_icon: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/ContentSection/ContentIcon
@onready var content_name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentSection/ContentName
@onready var content_amount_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentSection/ContentAmount
@onready var quality_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ProgressSection/QualityLabel
@onready var progress_bar: ProgressBar = $PanelContainer/MarginContainer/VBoxContainer/ProgressSection/ProgressBar
@onready var days_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ProgressSection/DaysLabel
@onready var place_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionSection/PlaceButton
@onready var collect_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionSection/CollectButton
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton

## Reference to the jar being interacted with.
var _jar: FermentationJarInteractable = null

## Item selection state for placing content.
var _selected_item_id: StringName = &""


func _ready() -> void:
	if place_button:
		place_button.pressed.connect(_on_place)
	if collect_button:
		collect_button.pressed.connect(_on_collect)
	if close_button:
		close_button.pressed.connect(_on_close)
	visibility_changed.connect(_on_visibility_changed)
	refresh()


func _on_visibility_changed() -> void:
	if visible:
		refresh.call_deferred()


func setup(jar: FermentationJarInteractable) -> void:
	## Set the jar reference and refresh the display.
	_jar = jar
	refresh()


func refresh() -> void:
	## Update all UI elements based on current jar state.
	if _jar == null:
		_show_empty()
		return

	if _jar.content_item_id == &"":
		_show_empty_slot()
	else:
		_show_content()

	_update_buttons()


func _show_empty() -> void:
	## Show completely empty state (no jar reference).
	if content_icon:
		content_icon.texture = null
	if content_name_label:
		content_name_label.text = "未选择发酵坛"
	if content_amount_label:
		content_amount_label.text = ""
	if quality_label:
		quality_label.text = "品质: —"
	if progress_bar:
		progress_bar.value = 0
	if days_label:
		days_label.text = ""


func _show_empty_slot() -> void:
	## Show jar with empty slot (ready to place content).
	if content_icon:
		content_icon.texture = null
	if content_name_label:
		content_name_label.text = "[空] 可放入物料"
	if content_amount_label:
		content_amount_label.text = ""
	if quality_label:
		quality_label.text = "品质: —"
	if progress_bar:
		progress_bar.value = 0
	if days_label:
		days_label.text = "等待放入物料"


func _show_content() -> void:
	## Show jar with fermenting content.
	var item_id: StringName = _jar.content_item_id
	var info: Dictionary = InventoryManager.get_item_info(item_id)

	if content_icon:
		var tex: Texture2D = InventoryManager.get_item_icon(item_id)
		content_icon.texture = tex
	if content_name_label:
		content_name_label.text = info.get("name", String(item_id))
	if content_amount_label:
		content_amount_label.text = "x%d" % _jar.content_amount

	# Quality tier display
	var tiers: Array[Dictionary] = [
		{"name": "普通", "quality": 10},
		{"name": "优质", "quality": 16},
		{"name": "珍藏", "quality": 22},
	]
	var tier_idx: int = _jar.current_quality_tier
	var tier_name: String = "普通"
	if tier_idx < tiers.size():
		tier_name = tiers[tier_idx]["name"]
	# Show filled dots for reached tiers and empty for remaining
	var dots: String = ""
	for i in tiers.size():
		if i <= tier_idx:
			dots += "●"
		else:
			dots += "○"
	if quality_label:
		quality_label.text = "品质: %s %s" % [dots, tier_name]

	# Progress bar: each tier takes 4 days, max 12 days for top tier
	var max_days: int = tiers.size() * 4
	var current: int = _jar.fermentation_days
	if progress_bar:
		progress_bar.max_value = max_days
		progress_bar.value = current
	if days_label:
		days_label.text = "发酵进度: %d / %d 天" % [current, max_days]


func _update_buttons() -> void:
	if place_button:
		place_button.disabled = _jar == null or _jar.content_item_id != &""
	if collect_button:
		collect_button.disabled = _jar == null or _jar.content_item_id == &""


func _on_place() -> void:
	## Open a simple item picker to select fermentable item from inventory.
	if _jar == null or _jar.content_item_id != &"":
		return
	# For now, use a simple approach: try to place the first fermentable item found.
	# Fermentable items: GlutinousRice, Soybean, Wheat
	var fermentable_items: Array[StringName] = [&"GlutinousRice", &"Soybean", &"Wheat"]
	for item_id: StringName in fermentable_items:
		if InventoryManager.has_item(item_id, 1):
			if _jar.place_content(item_id, 1):
				EventBus.notification_requested.emit("已放入 %s" % InventoryManager.get_item_info(item_id).get("name", ""))
				refresh()
				return
	EventBus.notification_requested.emit("没有可发酵的物料!")


func _on_collect() -> void:
	## Collect the fermented product from the jar.
	if _jar == null or _jar.content_item_id == &"":
		return
	var item_id: StringName = _jar.content_item_id
	var info: Dictionary = InventoryManager.get_item_info(item_id)
	var amount: int = _jar.content_amount
	_jar.collect()
	EventBus.notification_requested.emit("取出了 %s x%d" % [info.get("name", ""), amount])
	refresh()


func _on_close() -> void:
	GameUI.close_panel()
