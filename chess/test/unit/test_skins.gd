extends GutTest

var arena: Arena


func before_each() -> void:
	arena = ArenaHelper.create_arena(self)


func test_old_tile_art_is_hidden_but_the_tiles_still_work() -> void:
	for area_name in ["Board", "Bench", "Relics"]:
		var area: PlayArea = arena.get_node(area_name)
		# self_modulate does not reach the tile quadrants, only `enabled` stops drawing them.
		assert_false(area.enabled, area_name)
		assert_true(area.visible, "%s children (units, highlights) still show" % area_name)
		assert_eq(area.get_global_from_tile(Vector2i(0, 1)), area.global_position + Vector2(4, 12), "%s tile math still works" % area_name)


func test_board_skin_checkers_like_the_moodboard() -> void:
	var skin: BoardSkin = arena.get_node("Board/BoardSkin")
	
	assert_eq(skin.get_tile_color(Vector2i(0, 0)), skin.light_color, "top-left is light")
	assert_eq(skin.get_tile_color(Vector2i(1, 0)), skin.dark_color)
	assert_eq(skin.get_tile_color(Vector2i(0, 4)), skin.light_color, "A1 is light")


func test_board_labels() -> void:
	var skin: BoardSkin = arena.get_node("Board/BoardSkin")
	
	assert_eq(skin.get_row_label(0), "5")
	assert_eq(skin.get_row_label(4), "1")
	assert_eq(skin.get_column_label(0), "A")
	assert_eq(skin.get_column_label(4), "E")


func test_board_skin_is_drawn_under_the_pieces() -> void:
	var skin: BoardSkin = arena.get_node("Board/BoardSkin")
	
	assert_eq(skin.get_index(), 0)
	assert_eq(skin.position, Vector2.ZERO)


func test_holder_dots_sit_on_the_slots() -> void:
	for area_name in ["Bench", "Relics"]:
		var area: PlayArea = arena.get_node(area_name)
		var skin: SlotHolderSkin = area.get_node("HolderSkin")
		assert_eq(skin.slots, area.unit_grid.size.y, area_name)
		assert_eq(skin.get_index(), 0, "%s skin is drawn first" % area_name)
		for i in skin.slots:
			assert_eq(skin.to_global(skin.get_slot_center(i)), area.get_global_from_tile(Vector2i(0, i)), "%s slot %d" % [area_name, i])


func test_holder_panel_surrounds_every_slot() -> void:
	var skin: SlotHolderSkin = arena.get_node("Bench/HolderSkin")
	var panel := skin.get_panel_rect()
	
	for i in skin.slots:
		assert_true(panel.has_point(skin.get_slot_center(i)))


func test_bench_and_relic_holders_have_different_looks() -> void:
	var bench: SlotHolderSkin = arena.get_node("Bench/HolderSkin")
	var relics: SlotHolderSkin = arena.get_node("Relics/HolderSkin")
	
	assert_ne(bench.panel_color, relics.panel_color)
	assert_eq(relics.shadow_color.a, 0.0)


func test_gambit_icons_line_up_with_relic_slots() -> void:
	var relics: PlayArea = arena.get_node("Relics")
	var bar: GambitBar = arena.get_node("Hud/GambitBar")
	
	assert_eq(bar.position + GambitData.ICON_SIZE / 2, relics.get_global_from_tile(Vector2i(0, 0)))


func test_highlights_use_the_tile_selection_art() -> void:
	const SELECTION_TILESET := preload("res://assets/sprites/tiles/tile_selection_tileset.tres")
	var layers := [arena.get_node("Board/Highlight"), arena.get_node("Bench/Highlight"), arena.get_node("Relics/Highlight"), arena.get_node("Board/MoveHints")]
	for layer: TileMapLayer in layers:
		assert_eq(layer.tile_set, SELECTION_TILESET, str(layer.get_path()))
		# 64 px tiles at 1/8 scale cover exactly one 8 px board cell.
		assert_eq(Vector2(layer.tile_set.tile_size) * layer.scale, Arena.CELL_SIZE, str(layer.get_path()))


func test_hover_highlight_lands_on_the_hovered_tile() -> void:
	var board: PlayArea = arena.board
	var highlighter: TileHighlighter = board.get_node("TileHighlighter")
	var layer: TileMapLayer = board.get_node("Highlight")
	
	highlighter._update_tile(Vector2i(2, 3))
	
	assert_eq(layer.get_used_cells(), [Vector2i(2, 3)] as Array[Vector2i])
	assert_eq(layer.to_global(layer.map_to_local(Vector2i(2, 3))), board.get_global_from_tile(Vector2i(2, 3)))


func test_background_skin_replaces_the_old_background() -> void:
	assert_false(arena.get_node("Visuals/Background").visible)
	var skin: BackgroundSkin = arena.get_node("Visuals/BackgroundSkin")
	assert_true(skin.visible)
	assert_eq(skin.size, Vector2(160, 80))


# Regression: the editor once dropped the exported node arrays when saving arena.tscn,
# and nothing could be dragged any more.
func test_arena_scene_wires_board_and_bench() -> void:
	for node_name in ["UnitMover", "UnitSeller"]:
		var node: Node = arena.get_node(node_name)
		assert_eq(node.board, arena.board, node_name)
		assert_eq(node.bench, arena.get_node("Bench"), node_name)
		assert_eq(node.play_areas, [arena.board, arena.get_node("Bench")] as Array[PlayArea], node_name)


func test_player_pieces_are_draggable_when_preparing() -> void:
	for unit in arena.get_node("Bench").unit_grid.get_all_units():
		assert_true(unit.drag_and_drop.enabled)


func test_holder_shadow_stays_inside_the_panel_away_from_corners() -> void:
	var skin: SlotHolderSkin = arena.get_node("Bench/HolderSkin")
	var panel := skin.get_panel_rect()
	var shadow := skin.get_shadow_rect()
	
	assert_true(panel.encloses(shadow))
	assert_gt(shadow.position.y, panel.position.y, "skips the top corner")
	assert_lt(shadow.end.y, panel.end.y, "skips the bottom corner")
