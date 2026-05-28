# Time System Fix Plan

## Problem Statement

The time system starts advancing as soon as the game launches, even before the player selects "New Game" or loads a save. This happens because TimeManager is set up as an autoload singleton and begins processing immediately.

## Solution Overview

We need to modify the time system so that it only starts advancing after the player has actually started a game (either new game or loaded a save).

## Implementation Steps

### 1. Add Game Started Flag to TimeManager

Add a `game_started` boolean variable to the TimeManager to track when the actual gameplay has begun.

```gd
# In core/time_manager.gd
var game_started: bool = false
```

### 2. Modify TimeManager Process Function

Update the `_process` function to only advance time when `game_started` is true.

```gd
# In core/time_manager.gd
func _process(delta: float) -> void:
	if not game_started or _time_paused or is_sleeping:
		return
	_accumulated_real_seconds += delta * time_speed_multiplier
	var quarters_elapsed: int = int(_accumulated_real_seconds / SECONDS_PER_GAME_QUARTER)
	if quarters_elapsed > 0:
		_accumulated_real_seconds -= quarters_elapsed * SECONDS_PER_GAME_QUARTER
		for i in quarters_elapsed:
			_advance_quarter()
```

### 3. Update GameManager to Set Game Started Flag

Modify both `new_game()` and `load_game()` functions in GameManager to set the `game_started` flag when a game is actually started.

```gd
# In core/game_manager.gd - new_game function
func new_game() -> void:
	TimeManager.game_started = true
	TimeManager.load_save_data(_default_time_data())
	PlayerData.load_save_data(_default_player_data())
	InventoryManager._initialize_starting_items()
	GameUI.show_game_ui()
	SceneManagerAutoload._on_scene_change_requested("res://scenes/world/WorldMap.tscn", &"farm_spawn")

# In core/game_manager.gd - load_game function
func load_game(slot: int) -> void:
	# ... existing code ...

	TimeManager.game_started = true
	TimeManager.load_save_data(data.get("time", {}))
	PlayerData.load_save_data(data.get("player", {}))
	# ... rest of existing code ...
```

## Testing Plan

1. Launch the game and verify that time does NOT advance on the main menu
2. Start a new game and verify that time DOES advance
3. Return to main menu and launch again to verify time doesn't advance
4. Load a saved game and verify that time DOES advance
5. Verify that saving and loading preserves the correct time state

## Files to Modify

1. `core/time_manager.gd` - Add game_started flag and modify \_process function
2. `core/game_manager.gd` - Set game_started flag in new_game and load_game functions

## Risk Assessment

- Low risk: This is a straightforward addition that adds a gate to existing functionality
- No data loss risk: We're only adding a check, not changing how time advancement works
- Backward compatibility: Existing save files will work correctly as we're setting the flag when loading

## Rollback Plan

If issues arise, we can simply revert the changes to restore the original behavior where time always advances.
