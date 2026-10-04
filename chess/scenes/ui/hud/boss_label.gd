## Names the boss during a boss battle; hover for its rule. Hidden otherwise.
class_name BossLabel
extends Label


func _ready() -> void:
	hide()


func show_boss(boss: BossData) -> void:
	text = "BOSS: %s" % boss.display_name.get_slice(" ", 0)
	Tooltip.attach(self, boss.display_name, "Stage %d boss" % RunState.stage, boss.description, Tooltip.RARITY_COLORS[GambitData.Rarity.EPIC])
	show()
