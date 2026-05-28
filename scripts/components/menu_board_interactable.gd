class_name MenuBoardInteractable
extends Interactable


func _ready() -> void:
	super._ready()
	interaction_name = "菜单看板"
	interaction_hint = "[空格] 菜单看板"


func interact() -> void:
	super.interact()
	if not UnlockManager.check_and_warn(&"menu_edit"):
		return
	if GameUI:
		var menu_panel: Control = GameUI.get_panel(&"MenuEditor")
		if menu_panel:
			GameUI.open_panel(menu_panel)
