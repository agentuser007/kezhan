# Hotbar & Shop Fix Plan

## Issue 1: Player Initial Items Not Showing in Hotbar

### Root Cause

In [`HotbarNew._create_slot()`](ui/hotbar/HotbarNew.gd:33), the node hierarchy for each slot is:

```
PanelContainer (the slot)
  └── MarginContainer
      └── TextureRect (name="Icon")    ← Icon is INSIDE MarginContainer
  └── Label (name="CountLabel")        ← direct child of PanelContainer
  └── Label (name="KeyLabel")          ← direct child of PanelContainer
```

However, in [`HotbarNew._update_display()`](ui/hotbar/HotbarNew.gd:115), the code does:

```gdscript
var icon: TextureRect = slot.get_node_or_null("Icon")
```

This looks for `"Icon"` as a **direct child** of the PanelContainer slot. Since `Icon` is actually a child of `MarginContainer`, `get_node_or_null("Icon")` returns **null**. As a result, the icon texture is never set, and hotbar items appear invisible even though the inventory data is correct.

The `CountLabel` and `KeyLabel` work fine because they ARE direct children of the PanelContainer.

### What the player sees

- The hotbar slots are rendered at the bottom of the screen
- The 4 tool slots (WateringCan, Hoe, Sickle, Axe) and any items placed in hotbar indices appear as empty slots
- Selecting a slot with the number keys still works functionally — the item IS equipped, just not visible

### Fix

In [`HotbarNew._update_display()`](ui/hotbar/HotbarNew.gd:115), change:

```gdscript
# BEFORE (broken):
var icon: TextureRect = slot.get_node_or_null("Icon")

# AFTER (fixed):
var icon: TextureRect = slot.get_node_or_null("MarginContainer/Icon")
```

This single-line change resolves the issue. The inventory data and signal flow are all correct — only the node path was wrong.

---

## Issue 2: Shop Buy Panel Shows No Products

### Root Cause

The [`ShopUI._ready()`](ui/shop/ShopUI.gd:23) calls `_refresh_all()` which populates the buy list from `InventoryManager._item_registry`. This works correctly during autoload initialization because `InventoryManager` loads before `GameUI`.

However, there are two problems:

1. **No refresh on open**: When the player opens the shop via [`ShopInteractable.interact()`](scripts/components/shop_interactable.gd:11), `GameUI.open_panel()` only sets `visible = true`. It does NOT call any refresh method on ShopUI. If the item registry changes or the list rendering becomes stale while the panel is hidden, the buy list may appear empty.

2. **Stale rendering after hidden**: The `GameUI` starts with `visible = false` and `process_mode = DISABLED`. The `ShopUI._ready()` populates the buy list while the entire `CanvasLayer` is hidden. In some Godot versions, `ItemList` widgets may not properly render their items when they become visible after being hidden since scene load.

### What the player sees

- Opening the shop shows the Buy tab with an empty item list
- The category dropdown may show categories but selecting them still shows no items
- The Sell tab may work correctly if the player has items in inventory

### Fix

Add a `visibility_changed` signal connection in [`ShopUI._ready()`](ui/shop/ShopUI.gd:23) so the panel refreshes every time it becomes visible:

```gdscript
func _ready() -> void:
    # ... existing connections ...
    visibility_changed.connect(_on_visibility_changed)
    _create_feedback_label()
    _refresh_all()


func _on_visibility_changed() -> void:
    if visible:
        _refresh_all()
```

This ensures:

- The buy list is always populated when the panel opens
- Gold display is updated to current value
- Sell list reflects current inventory
- Any rendering staleness from being hidden is resolved

---

## Summary of Changes

| File                                                   | Change                                                                         | Impact                                         |
| ------------------------------------------------------ | ------------------------------------------------------------------------------ | ---------------------------------------------- |
| [`ui/hotbar/HotbarNew.gd`](ui/hotbar/HotbarNew.gd:115) | Fix Icon node path from `"Icon"` to `"MarginContainer/Icon"`                   | Hotbar items now display their icons correctly |
| [`ui/shop/ShopUI.gd`](ui/shop/ShopUI.gd:23)            | Add `visibility_changed` signal connection + `_on_visibility_changed()` method | Shop buy list always refreshes when opened     |

Both fixes are minimal, targeted, and don't affect any other systems.
