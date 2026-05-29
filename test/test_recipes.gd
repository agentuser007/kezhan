extends GdUnitTestSuite

func test_unlocked_recipes() -> void:
	print("--- GDUNIT TEST RECIPES ---")
	var recipes = InventoryManager.get_all_recipes()
	print("All recipes count: ", recipes.size())
	for r in recipes:
		print("Recipe: ID=", r.get("id"), ", Name=", r.get("name"), ", RequiredLevel=", r.get("required_cooking_level"))
		
	var unlocked = InventoryManager.get_unlocked_recipes()
	print("Unlocked recipes count: ", unlocked.size())
	for r in unlocked:
		print("Unlocked Recipe: ID=", r.get("id"), ", Name=", r.get("name"))
		
	assert_that(unlocked.size()).is_greater(0)
