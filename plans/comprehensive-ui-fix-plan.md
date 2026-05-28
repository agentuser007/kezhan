# Comprehensive UI Fix Plan

## Issues Identified

1. **Hotbar Icons Not Displaying**
   - Problem: HotbarNew.gd cannot find icon nodes due to incorrect path resolution
   - Root Cause: Generated node names like "@MarginContainer@57" instead of expected "MarginContainer"
   - Solution: Modify \_update_display() function to correctly find icon nodes

2. **Shop UI Showing No Items**
   - Problem: ShopUI not refreshing when opened
   - Root Cause: No visibility change handler to refresh the buy list
   - Solution: Add visibility_changed signal connection to refresh on open

3. **Menu Editor Showing No Dishes**
   - Problem: MenuEditor not finding unlocked recipes
   - Root Cause: Unlock conditions not met or recipe registry issues
   - Solution: Verify unlock conditions and recipe registration

4. **Fermenter UI Missing Control Panel**
   - Problem: FermenterUI not displaying properly
   - Root Cause: Scene structure or initialization issues
   - Solution: Verify scene structure and initialization

5. **Barn Management UI Not Appearing**
   - Problem: BarnManagementUI not showing when opened
   - Root Cause: Initialization or visibility conditions
   - Solution: Verify scene initialization and visibility handling

6. **Cooked Items Not Appearing in Inventory**
   - Problem: CookingUI not properly adding items to inventory
   - Root Cause: Inventory update issues after cooking
   - Solution: Verify inventory update mechanism in CookingUI

7. **Farming Tools Not Properly Registered**
   - Problem: Farming tools missing from hotbar
   - Root Cause: Tools not registered with icons or not placed in hotbar
   - Solution: Verify tool registration and hotbar placement

## Detailed Solutions

### 1. Hotbar Icons Fix

**File:** [`ui/hotbar/HotbarNew.gd`](ui/hotbar/HotbarNew.gd)

**Issue:** The `_update_display()` function tries to find icon nodes using a fixed path "MarginContainer/Icon", but Godot generates unique names like "@MarginContainer@57" for duplicated nodes.

**Solution:** Modify the node lookup to work with generated names:

```gdscript
func _update_display() -> void:
	for i: int in _slot_controls.size():
		var slot: Control = _slot_controls[i]
		# Instead of using fixed path, iterate through children to find the icon
		var icon: TextureRect = null
		for child in slot.get_children():
			if child is MarginContainer:
				for grandchild in child.get_children():
					if grandchild is TextureRect and grandchild.name == "Icon":
						icon = grandchild
						break
				if icon:
					break
		var count_label: Label = slot.get_node_or_null("CountLabel")

		if icon != null:
			var item: Dictionary = InventoryManager.get_hotbar_item(i)
			if not item.is_empty():
				var tex: Texture2D = InventoryManager.get_item_icon(StringName(item["id"]))
				icon.texture = tex
				icon.show()
			else:
				icon.hide()

		if count_label != null:
			var item: Dictionary = InventoryManager.get_hotbar_item(i)
			if not item.is_empty() and item["amount"] > 1:
				count_label.text = str(item["amount"])
				count_label.show()
			else:
				count_label.hide()
```

### 2. Shop UI Refresh Fix

**File:** [`ui/shop/ShopUI.gd`](ui/shop/ShopUI.gd)

**Issue:** The shop UI doesn't refresh when opened, leading to empty lists if opened after initialization.

**Solution:** Add visibility change handler to refresh the UI when it becomes visible:

```gdscript
func _ready() -> void:
	# Existing code...
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		_refresh_all()
```

### 3. Menu Editor Recipe Fix

**File:** [`ui/menu_editor/MenuEditor.gd`](ui/menu_editor/MenuEditor.gd)

**Issue:** Menu editor not finding unlocked recipes.

**Solution:** Verify that recipes are properly registered and unlocked:

1. Check that recipes are registered in InventoryManager with proper IDs
2. Ensure UnlockManager has the "menu_edit" feature unlocked
3. Verify cooking level requirements for recipes

### 4. Fermenter UI Initialization Fix

**File:** [`ui/fermenter/FermenterUI.gd`](ui/fermenter/FermenterUI.gd)

**Issue:** Fermenter UI not displaying properly.

**Solution:** Ensure proper initialization and scene structure:

1. Verify all UI elements are properly referenced
2. Check that the setup() method is called with a valid jar reference
3. Ensure refresh() is called after setup

### 5. Barn Management UI Initialization Fix

**File:** [`ui/barn/BarnManagementUI.gd`](ui/barn/BarnManagementUI.gd)

**Issue:** Barn management UI not appearing.

**Solution:** Ensure proper initialization:

1. Verify that the setup() method is called with a valid barn reference
2. Check that refresh() is called after setup
3. Ensure all UI elements are properly referenced

### 6. Cooking UI Inventory Update Fix

**File:** [`ui/cooking/CookingUI.gd`](ui/cooking/CookingUI.gd)

**Issue:** Cooked items not appearing in inventory.

**Solution:** Verify the inventory update mechanism:

1. Check that \_on_start_cooking() properly calls InventoryManager.add_item()
2. Ensure EventBus.inventory_changed.emit() is called after adding items
3. Verify that output_id and output_amount are properly set in recipes

### 7. Farming Tools Registration Fix

**Files:**

- [`core/inventory_manager.gd`](core/inventory_manager.gd)
- [`ui/hotbar/HotbarNew.gd`](ui/hotbar/HotbarNew.gd)

**Issue:** Farming tools not properly registered or placed in hotbar.

**Solution:**

1. Verify that all farming tools are registered in InventoryManager.\_item_registry with proper IDs and icons
2. Ensure \_initialize_starting_items() includes farming tools in the hotbar
3. Check that tool icons are properly loaded and registered

## Implementation Steps

### Step 1: Fix Hotbar Icons

- Modify [`ui/hotbar/HotbarNew.gd`](ui/hotbar/HotbarNew.gd) to correctly find icon nodes

### Step 2: Fix Shop UI Refresh

- Add visibility change handler to [`ui/shop/ShopUI.gd`](ui/shop/ShopUI.gd)

### Step 3: Fix Menu Editor Recipes

- Verify recipe registration and unlock conditions in [`ui/menu_editor/MenuEditor.gd`](ui/menu_editor/MenuEditor.gd)

### Step 4: Fix Fermenter UI Initialization

- Ensure proper initialization in [`ui/fermenter/FermenterUI.gd`](ui/fermenter/FermenterUI.gd)

### Step 5: Fix Barn Management UI Initialization

- Ensure proper initialization in [`ui/barn/BarnManagementUI.gd`](ui/barn/BarnManagementUI.gd)

### Step 6: Fix Cooking UI Inventory Updates

- Verify inventory update mechanism in [`ui/cooking/CookingUI.gd`](ui/cooking/CookingUI.gd)

### Step 7: Fix Farming Tools Registration

- Verify tool registration in [`core/inventory_manager.gd`](core/inventory_manager.gd)
- Ensure tools are placed in hotbar

## Testing Plan

1. **Hotbar Testing**
   - Start a new game
   - Verify that initial items appear in the hotbar
   - Check that item icons display correctly

2. **Shop UI Testing**
   - Open the shop UI
   - Verify that items appear in the buy list
   - Check that items can be purchased

3. **Menu Editor Testing**
   - Unlock menu editing feature
   - Open menu editor
   - Verify that dishes appear in the available list

4. **Fermenter UI Testing**
   - Unlock fermenter feature
   - Interact with fermentation jar
   - Verify that UI displays properly

5. **Barn Management UI Testing**
   - Unlock barn management feature
   - Interact with barn control box
   - Verify that UI displays properly

6. **Cooking UI Testing**
   - Open cooking UI
   - Select a recipe
   - Cook the recipe
   - Verify that cooked items appear in inventory

7. **Farming Tools Testing**
   - Start a new game
   - Verify that farming tools appear in hotbar
   - Check that tool icons display correctly

## Expected Outcomes

After implementing these fixes:

1. Player's initial道具 (items) will appear in the hotbar/screen下方的背包栏 (bottom screen backpack bar)
2. 杂货铺的购买面板 (grocery store purchase panel) will show 商品 (items)
3. 今日菜单 (today's menu) will have 可添加的菜品 (dishes to add)
4. 发酵罐 (fermenter) will have a control panel
5. 烹饪完之后的菜品 (cooked dishes) will appear in the backpack
6. 畜棚 (livestock shed) 管理面板 (management panel) will have a UI
7. All farming tools will be properly registered with icons and placed in the hotbar
