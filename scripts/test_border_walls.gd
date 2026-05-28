extends Node

func _ready() -> void:
    set_process(true)

func _process(_delta: float) -> void:
    var wm: Node = _find_world_map()
    if wm == null:
        return
    set_process(false)
    _run_tests(wm)

func _find_world_map() -> Node:
    var root: Node = get_tree().root
    for child in root.get_children():
        if child.name == "WorldMap":
            return child
        for sub in child.get_children():
            if sub.name == "WorldMap":
                return sub
            for deep in sub.get_children():
                if deep.name == "WorldMap":
                    return deep
    return null

func _run_tests(wm: Node) -> void:
    var ol: TileMapLayer = wm.get_node("ObjectLayer")
    var top_count: int = 0
    var bottom_count: int = 0
    var left_count: int = 0
    var right_count: int = 0
    for x in range(wm.farm_grid_width):
        if ol.get_cell_source_id(Vector2i(x, 0)) != -1:
            top_count += 1
        if ol.get_cell_source_id(Vector2i(x, wm.farm_grid_height - 1)) != -1:
            bottom_count += 1
    for y in range(wm.farm_grid_height):
        if ol.get_cell_source_id(Vector2i(0, y)) != -1:
            left_count += 1
        if ol.get_cell_source_id(Vector2i(wm.farm_grid_width - 1, y)) != -1:
            right_count += 1
    var cam: Camera2D = wm.player.get_node("Camera2D")
    push_warning("[BT] grid=%dx%d ts=%s top=%d/%d bot=%d/%d left=%d/%d right=%d/%d cam=[%d,%d,%d,%d] drag=%s/%s" % [wm.farm_grid_width, wm.farm_grid_height, str(ol.tile_set != null), top_count, wm.farm_grid_width, bottom_count, wm.farm_grid_width, left_count, wm.farm_grid_height, right_count, wm.farm_grid_height, cam.limit_left, cam.limit_top, cam.limit_right, cam.limit_bottom, str(cam.drag_horizontal_enabled), str(cam.drag_vertical_enabled)])
    var sb: int = 0
    for child in wm.get_children():
        if child is StaticBody2D:
            sb += 1
    var exp: int = 2 * wm.farm_grid_width + 2 * (wm.farm_grid_height - 2)
    var act: int = top_count + bottom_count + left_count + right_count
    if act == exp and sb == 4:
        push_warning("[BT] PASS tiles=%d/%d bodies=%d/4" % [act, exp, sb])
    else:
        push_warning("[BT] FAIL tiles=%d/%d bodies=%d/4" % [act, exp, sb])
    queue_free()
