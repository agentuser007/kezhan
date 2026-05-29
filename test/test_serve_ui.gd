extends GdUnitTestSuite

func test_serve_ui_behavior() -> void:
	print("--- GDUNIT TEST SERVE UI BEHAVIOR ---")
	
	# Initialize inventory items if they are empty (happens when run under standalone headless test tree)
	if InventoryManager.items.is_empty():
		InventoryManager._initialize_starting_items()
		
	# Load and instantiate ServeUI scene
	var serve_ui_scene = load("res://ui/serve/ServeUI.tscn")
	assert_that(serve_ui_scene).is_not_null()
	
	var serve_ui = serve_ui_scene.instantiate()
	assert_that(serve_ui).is_not_null()
	
	# Add to main tree
	var tree = Engine.get_main_loop()
	assert_that(tree).is_not_null()
	tree.root.add_child(serve_ui)
	
	# Wait for ready
	await tree.process_frame
	await tree.process_frame
	
	# Instantiate dummy guest npc (don't add to tree to avoid seating/pathfinding/bubble setup)
	var guest_script = load("res://scenes/inn/guest_controller.gd")
	assert_that(guest_script).is_not_null()
	
	var dummy_guest = guest_script.new()
	assert_that(dummy_guest).is_not_null()
	
	dummy_guest.ordered_recipe_id = &"hongshaorou"
	dummy_guest.ordered_item_id = &"DishHongshaorou"
	
	# Clear player inventory of DishHongshaorou first
	var current_amount = InventoryManager.get_amount(&"DishHongshaorou")
	if current_amount > 0:
		InventoryManager.remove_item(&"DishHongshaorou", current_amount)
		
	# 1. Test setup with 0 inventory count
	serve_ui.setup(dummy_guest)
	await tree.process_frame
	
	assert_that(serve_ui.content_name.text).is_equal("红烧肉")
	assert_that(serve_ui.serve_button.disabled).is_true()
	assert_that(serve_ui.placeholder_label.visible).is_true()
	assert_that(serve_ui.dish_list.visible).is_false()
	
	# 2. Test setup with inventory count > 0
	InventoryManager.add_item(&"DishHongshaorou", 3)
	serve_ui.refresh()
	await tree.process_frame
	
	assert_that(serve_ui.serve_button.disabled).is_false()
	assert_that(serve_ui.placeholder_label.visible).is_false()
	assert_that(serve_ui.dish_list.visible).is_true()
	assert_that(serve_ui.dish_list.item_count).is_greater(0)
	
	# Verify pricing calculation
	assert_that(serve_ui.content_price.text).contains("90 金")
	
	# Cleanup
	serve_ui.queue_free()
	dummy_guest.free()
