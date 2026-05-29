extends GdUnitTestSuite

func test_fermenter_ui_population() -> void:
	print("--- GDUNIT TEST FERMENTER UI POPULATION ---")
	
	# Load and instantiate FermenterUI scene
	var fermenter_ui_scene = load("res://ui/fermenter/FermenterUI.tscn")
	assert_that(fermenter_ui_scene).is_not_null()
	
	var fermenter_ui = fermenter_ui_scene.instantiate()
	assert_that(fermenter_ui).is_not_null()
	
	# Add to main tree
	var tree = Engine.get_main_loop()
	assert_that(tree).is_not_null()
	tree.root.add_child(fermenter_ui)
	
	# Show panel
	fermenter_ui.visible = true
	
	# Wait a couple of frames for ready and deferred setup
	await tree.process_frame
	await tree.process_frame
	
	# Verify lists and controls
	var ingredient_list = fermenter_ui.ingredient_list
	assert_that(ingredient_list).is_not_null()
	
	print("Ingredient list items count: ", ingredient_list.item_count)
	for i in range(ingredient_list.item_count):
		print("  Fermentable crop option: ", ingredient_list.get_item_text(i))
		
	# The crop picker should have exactly the 3 fermentable items (even if they have 0 count)
	assert_that(ingredient_list.item_count).is_equal(3)
	
	# Cleanup
	fermenter_ui.queue_free()
