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
	InventoryManager.add_item(_get_output_item_id(current_recipe_id), 1)
	current_state = StationState.IDLE
	current_recipe_id = &""
	cooking_progress = 0.0
	EventBus.cooking_finished.emit(station_id, current_recipe_id)


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


func _get_output_item_id(recipe_id: StringName) -> StringName:
	var recipes: Dictionary = {
		&"hongshaorou": &"HongshaoRou",
	}
	return recipes.get(recipe_id, recipe_id)
