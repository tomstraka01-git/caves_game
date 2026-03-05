extends Resource
class_name Inv

@export var items: Array[Item]
@export var stack_counts: Array[int]  

func add_item(item: Item, amount: int = 1) -> bool:
	if item.stackable:
		for i in items.size():
			if items[i].name == item.name and stack_counts[i] < item.max_stack:
				stack_counts[i] = min(stack_counts[i] + amount, item.max_stack)
				return true
	items.append(item)
	stack_counts.append(amount)
	return true

func remove_item(index: int, amount: int = 1) -> void:
	if index >= items.size(): return
	stack_counts[index] -= amount
	if stack_counts[index] <= 0:
		items.remove_at(index)
		stack_counts.remove_at(index)

func get_item_count(item_name: String) -> int:
	var total = 0
	for i in items.size():
		if items[i].name == item_name:
			total += stack_counts[i]
	return total
