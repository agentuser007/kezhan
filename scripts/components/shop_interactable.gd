class_name ShopInteractable
extends Interactable


func _ready() -> void:
	super._ready()
	interaction_name = "杂货铺"
	interaction_hint = "[空格] 杂货铺"


func interact() -> void:
	super.interact()
	if GameUI:
		var shop_panel: Control = GameUI.get_panel(&"ShopUI")
		if shop_panel:
			GameUI.open_panel(shop_panel)
