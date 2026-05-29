extends Node

# TavernManager - coordinates guest seats, daily menu, and today's business metrics.

var todays_menu: Array[StringName] = []
var active_seats: Array[Node] = []
var guest_occupancy: Dictionary = {} # Node (seat) -> Node (guest NPC)

# Daily Business Metrics (cleared daily and reported to DayTurnoverProcessor)
var daily_revenue: float = 0.0
var daily_reputation_change: float = 0.0

signal menu_changed
signal seat_registered(seat: Node)
signal seat_unregistered(seat: Node)


func _ready() -> void:
	# Start with basic recipes unlocked as starting menu
	todays_menu = [
		&"hongshaorou",
		&"qingzhengyu"
	]


func register_seat(seat: Node) -> void:
	if not active_seats.has(seat):
		active_seats.append(seat)
		seat_occupancy_check(seat)
		seat_registered.emit(seat)


func unregister_seat(seat: Node) -> void:
	if active_seats.has(seat):
		active_seats.erase(seat)
		guest_occupancy.erase(seat)
		seat_unregistered.emit(seat)


func seat_occupancy_check(seat: Node) -> void:
	if not guest_occupancy.has(seat):
		guest_occupancy[seat] = null


func get_random_open_seat() -> Node:
	var open_seats: Array[Node] = []
	for seat in active_seats:
		seat_occupancy_check(seat)
		if guest_occupancy[seat] == null and not is_seat_occupied_by_player(seat):
			open_seats.append(seat)
	if open_seats.is_empty():
		return null
	return open_seats[randi() % open_seats.size()]


func is_seat_occupied_by_player(seat: Node) -> bool:
	if seat.has_method("is_player_seated"):
		return seat.is_player_seated()
	return seat.get("_is_seated") == true


func set_seat_occupied(seat: Node, guest: Node) -> void:
	seat_occupancy_check(seat)
	guest_occupancy[seat] = guest


func set_seat_empty(seat: Node) -> void:
	seat_occupancy_check(seat)
	guest_occupancy[seat] = null


func get_todays_menu() -> Array[StringName]:
	return todays_menu


func set_todays_menu(menu: Array[StringName]) -> void:
	todays_menu = menu
	menu_changed.emit()


func add_revenue(amount: float) -> void:
	daily_revenue += amount
	PlayerData.gold += int(amount)
	EventBus.inventory_changed.emit() # Refresh gold display


func add_reputation(amount: float) -> void:
	daily_reputation_change += amount


func reset_daily_stats() -> void:
	daily_revenue = 0.0
	daily_reputation_change = 0.0


func get_save_data() -> Dictionary:
	var menu_strings: Array[String] = []
	for m in todays_menu:
		menu_strings.append(String(m))
	return {
		"todays_menu": menu_strings,
		"daily_revenue": daily_revenue,
		"daily_reputation_change": daily_reputation_change
	}


func load_save_data(data: Dictionary) -> void:
	var menu_strings = data.get("todays_menu", ["hongshaorou", "qingzhengyu"])
	todays_menu.clear()
	for m in menu_strings:
		todays_menu.append(StringName(m))
	daily_revenue = data.get("daily_revenue", 0.0)
	daily_reputation_change = data.get("daily_reputation_change", 0.0)


func reset() -> void:
	todays_menu = [&"hongshaorou", &"qingzhengyu"]
	reset_daily_stats()

