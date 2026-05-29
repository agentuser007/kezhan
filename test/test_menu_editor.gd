extends GdUnitTestSuite

func test_menu_editor_population() -> void:
	print("--- GDUNIT TEST MENU EDITOR POPULATION ---")
	
	# Load and instantiate MenuEditor scene directly
	var menu_editor_scene = load("res://ui/menu_editor/MenuEditor.tscn")
	assert_that(menu_editor_scene).is_not_null()
	
	var menu_editor = menu_editor_scene.instantiate()
	assert_that(menu_editor).is_not_null()
	
	# Add it to the tree so it initializes fully
	var tree = Engine.get_main_loop()
	assert_that(tree).is_not_null()
	tree.root.add_child(menu_editor)
	
	# Set it visible to trigger visibility changed signal and deferred population
	menu_editor.visible = true
	
	# Wait a frame or two for deferred calls to execute
	await tree.process_frame
	await tree.process_frame
	
	# Inspect lists
	var available_list = menu_editor.available_list
	var today_list = menu_editor.today_menu_list
	
	print("Lists inside MenuEditor:")
	print("  available_list count: ", available_list.item_count if available_list else "NULL")
	print("  today_menu_list count: ", today_list.item_count if today_list else "NULL")
	
	if available_list:
		for i in range(available_list.item_count):
			print("    Available dish: ", available_list.get_item_text(i))
			
	if today_list:
		for i in range(today_list.item_count):
			print("    Today's dish: ", today_list.get_item_text(i))
			
	# Assert that items are indeed populated
	assert_that(available_list).is_not_null()
	assert_that(available_list.item_count).is_greater(0)
	
	# Cleanup
	menu_editor.queue_free()
