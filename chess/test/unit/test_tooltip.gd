extends GutTest

const SCREEN := Vector2(160, 80)
const SIZE := Vector2(30, 10)


func after_each() -> void:
	Tooltip.hide_tooltip()


func test_tooltip_goes_above_and_centered() -> void:
	var pos := Tooltip.get_tooltip_position(Rect2(60, 40, 8, 8), SIZE, SCREEN)
	
	assert_eq(pos, Vector2(64 - 15, 40 - 10 - 1))


func test_tooltip_goes_below_when_no_room_above() -> void:
	var pos := Tooltip.get_tooltip_position(Rect2(60, 2, 8, 8), SIZE, SCREEN)
	
	assert_eq(pos.y, 10.0 + 1)


func test_tooltip_stays_inside_the_screen() -> void:
	var left := Tooltip.get_tooltip_position(Rect2(0, 40, 8, 8), SIZE, SCREEN)
	var right := Tooltip.get_tooltip_position(Rect2(155, 40, 8, 8), SIZE, SCREEN)
	
	assert_eq(left.x, 0.0)
	assert_eq(right.x, SCREEN.x - SIZE.x)


func test_show_and_hide() -> void:
	var owner_node: Node = autofree(Node.new())
	
	Tooltip.show_tooltip(owner_node, Rect2(60, 40, 8, 8), "Knight", "Rare", "Jumps in an L shape.")
	
	assert_true(Tooltip.is_showing())
	assert_eq(Tooltip.title.text, "Knight")
	assert_true(Tooltip.subtitle.visible)
	assert_true(Tooltip.body.visible)
	
	Tooltip.hide_tooltip(owner_node)
	assert_false(Tooltip.is_showing())


func test_empty_lines_are_hidden() -> void:
	Tooltip.show_tooltip(autofree(Node.new()), Rect2(60, 40, 8, 8), "Pawn")
	
	assert_false(Tooltip.subtitle.visible)
	assert_false(Tooltip.body.visible)


func test_hiding_for_another_owner_keeps_the_tooltip() -> void:
	var first: Node = autofree(Node.new())
	var second: Node = autofree(Node.new())
	Tooltip.show_tooltip(second, Rect2(60, 40, 8, 8), "Second")
	
	Tooltip.hide_tooltip(first)
	
	assert_true(Tooltip.is_showing())


func test_tooltip_hides_when_its_owner_is_freed() -> void:
	var owner_node := Node.new()
	Tooltip.show_tooltip(owner_node, Rect2(60, 40, 8, 8), "Gone")
	
	owner_node.free()
	await wait_process_frames(2)
	
	assert_false(Tooltip.is_showing())


func test_long_descriptions_wrap() -> void:
	Tooltip.show_tooltip(autofree(Node.new()), Rect2(60, 40, 8, 8), "King", "", "Moves 1 in any direction. Losing it loses the battle.")
	
	assert_eq(Tooltip.body.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
	assert_lte(Tooltip.panel.get_combined_minimum_size().x, Tooltip.MAX_BODY_WIDTH + 8)


func test_short_descriptions_do_not_wrap() -> void:
	Tooltip.show_tooltip(autofree(Node.new()), Rect2(60, 40, 8, 8), "Rook", "", "Slides straight.")
	
	assert_eq(Tooltip.body.autowrap_mode, TextServer.AUTOWRAP_OFF)


func test_every_piece_type_has_a_description() -> void:
	for type in UnitStats.Type.values():
		assert_true(UnitStats.DESCRIPTIONS.has(type), UnitStats.Type.keys()[type])


func test_position_is_on_whole_pixels() -> void:
	var pos := Tooltip.get_tooltip_position(Rect2(60, 40, 8, 8), Vector2(31, 10), SCREEN)
	
	assert_eq(pos, pos.floor())
