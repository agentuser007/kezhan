class_name CookingStationInteractable
extends Interactable

enum StationState { IDLE, COOKING, FINISHED }

@export var station_type: StringName = &"stove"
@export var station_id: StringName = &"stove_1"
@export var is_player_reserved: bool = false
@export var auto_retain_recipe: bool = false

var current_state: StationState = StationState.IDLE
var current_recipe_id: StringName = &""
var cooking_progress: float = 0.0
var cooking_duration: float = 30.0
var saved_recipe_config: Dictionary = {}

signal cooking_progress_changed(progress: float)


func _ready() -> void:
	super._ready()
	add_to_group("cooking_stations")
	interaction_name = "灶台"
	interaction_hint = "[空格] 灶台"


func interact() -> void:
	super.interact()
	match current_state:
		StationState.IDLE:
			_open_cooking_ui()
		StationState.COOKING:
			_cancel_cooking()
		StationState.FINISHED:
			_collect_dish()


func _open_cooking_ui() -> void:
	EventBus.player_interacted.emit(self)
	EventBus.cooking_started.emit(station_id, current_recipe_id)
	if GameUI:
		var cooking_panel: Control = GameUI.get_panel(&"CookingUI")
		if cooking_panel:
			GameUI.open_panel(cooking_panel)


func _cancel_cooking() -> void:
	current_state = StationState.IDLE
	current_recipe_id = &""
	cooking_progress = 0.0


func _collect_dish() -> void:
	if current_recipe_id == &"":
		return
	
	var recipe: Dictionary = InventoryManager.get_recipe(current_recipe_id)
	var output_id: StringName = current_recipe_id
	var amount: int = 1
	if not recipe.is_empty():
		output_id = StringName(recipe.get("output_id", ""))
		amount = recipe.get("output_amount", 1)
	
	InventoryManager.add_item(output_id, amount)
	
	var finished_recipe: StringName = current_recipe_id
	current_state = StationState.IDLE
	current_recipe_id = &""
	cooking_progress = 0.0
	EventBus.cooking_finished.emit(station_id, finished_recipe)


func start_cooking(recipe_id: StringName, duration: float = 30.0) -> void:
	current_recipe_id = recipe_id
	cooking_duration = duration
	cooking_progress = 0.0
	current_state = StationState.COOKING
	EventBus.cooking_started.emit(station_id, recipe_id)


func _process(delta: float) -> void:
	if current_state == StationState.COOKING:
		cooking_progress += delta
		cooking_progress_changed.emit(cooking_progress / cooking_duration)
		if cooking_progress >= cooking_duration:
			current_state = StationState.FINISHED
			cooking_progress = cooking_duration


func get_interaction_text() -> String:
	match current_state:
		StationState.IDLE:
			return "[空格] 开始烹饪"
		StationState.COOKING:
			var percent: int = int((cooking_progress / cooking_duration) * 100.0)
			return "[空格] 正在烹饪 (%d%%) - 按空格取消" % percent
		StationState.FINISHED:
			var recipe: Dictionary = InventoryManager.get_recipe(current_recipe_id)
			var dish_name: String = recipe.get("name", "菜肴") if not recipe.is_empty() else "菜肴"
			return "[空格] 收集%s (烹饪完成!)" % dish_name
	return super.get_interaction_text()

