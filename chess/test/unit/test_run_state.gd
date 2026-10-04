extends GutTest

const HUD = preload("res://scenes/ui/hud/hud.tscn")


func before_each() -> void:
	RunState.reset()


func after_all() -> void:
	RunState.reset()


func test_starts_with_starting_money() -> void:
	assert_eq(RunState.money, RunState.STARTING_MONEY)


func test_add_money_emits_signal() -> void:
	watch_signals(RunState)
	
	RunState.add_money(5)
	RunState.add_money(3)
	
	assert_eq(RunState.money, 8)
	assert_signal_emitted_with_parameters(RunState, "money_changed", [8])


func test_reset() -> void:
	RunState.add_money(5)
	
	RunState.reset()
	
	assert_eq(RunState.money, RunState.STARTING_MONEY)


func test_money_label_follows_run_state() -> void:
	RunState.add_money(4)
	var hud: CanvasLayer = HUD.instantiate()
	add_child_autofree(hud)
	var label: Label = hud.get_node("MoneyLabel")
	
	assert_eq(label.text, "$4")
	
	RunState.add_money(3)
	
	assert_eq(label.text, "$7")
