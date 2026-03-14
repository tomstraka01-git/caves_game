extends Node

var level_completed: Array[bool] = [false, false, false, false]
var inventory: Inv = Inv.new()

var boss_level_unlocked = false
var final_level_unlocked = false
var shop_visited: bool = false
var npc_visited: bool = false

var _snapshot_items: Array = []
var _snapshot_counts: Array = []

func save_level_snapshot() -> void:
    _snapshot_items = []
    _snapshot_counts = []
    for item in inventory.items:
        _snapshot_items.append(item)
    for count in inventory.stack_counts:
        _snapshot_counts.append(count)

func restore_level_snapshot() -> void:
    inventory.items.clear()
    inventory.stack_counts.clear()
    for item in _snapshot_items:
        inventory.items.append(item)
    for count in _snapshot_counts:
        inventory.stack_counts.append(count)

func complete_level(index: int) -> void:
    if index >= 0 and index < level_completed.size():
        level_completed[index] = true

    save_level_snapshot()
