class_name MoneyLabel
extends Label


func _ready() -> void:
	RunState.money_changed.connect(_on_money_changed)
	_on_money_changed(RunState.money)


func _on_money_changed(money: int) -> void:
	text = "$%d" % money
