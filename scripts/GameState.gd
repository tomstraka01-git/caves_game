extends Node

var level_completed: Array[bool] = [false, false, false, false]
var inventory: Inv = Inv.new()

func complete_level(index: int) -> void:
	if index >= 0 and index < level_completed.size():
		level_completed[index] = true
