extends Panel

@onready var item_grid: GridContainer = $VBoxContainer/ItemGrid

const SLOT_SIZE = 96
const COLUMNS = 5
const ROWS = 4
var coin_scene = preload("res://scenes/coin.tscn")
@onready var player = get_parent().get_parent()



func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item_grid.columns = COLUMNS
	item_grid.add_theme_constant_override("h_separation", 4)
	item_grid.add_theme_constant_override("v_separation", 4)


	var panel_width = COLUMNS * (SLOT_SIZE + 4) + 16
	var panel_height = ROWS * (SLOT_SIZE + 4) + 16 + 64
	size = Vector2(panel_width, panel_height)


	var screen = get_viewport().get_visible_rect().size
	position = (screen / 2 - size / 2).round()


	var vbox = $VBoxContainer

	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)


	hide()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_inventory"):
		if visible:
			hide()
		else:
			_refresh()
			show()

func _refresh() -> void:
	for child in item_grid.get_children():
		child.queue_free()

	var total_slots = COLUMNS * ROWS

	for i in total_slots:
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		wrapper.mouse_filter = Control.MOUSE_FILTER_STOP 

		var slot = Panel.new()
		slot.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.clip_contents = true
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE 

		if i < GameState.inventory.items.size():
			var item = GameState.inventory.items[i]
			var count = GameState.inventory.stack_counts[i]

			var icon = TextureRect.new()
			icon.texture = item.texture
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.size = Vector2(SLOT_SIZE, SLOT_SIZE)
			icon.position = Vector2(0, 0)
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(icon)

			var label = Label.new()
			label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			label.text = str(count) if count > 1 else ""
			label.size = Vector2(SLOT_SIZE, 12)
			label.position = Vector2(0 - 6, SLOT_SIZE - 36).round()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			label.add_theme_font_size_override("font_size", 32)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE 

		
			var idx = i
			wrapper.gui_input.connect(func(event):
				_on_slot_clicked(event, idx)
			)

			wrapper.tooltip_text = item.name + "\n" + item.description
			wrapper.add_child(slot)
			wrapper.add_child(label)
		else:
			wrapper.add_child(slot)

		item_grid.add_child(wrapper)

func _on_slot_clicked(event: InputEvent, index: int) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	if index >= GameState.inventory.items.size():
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		_use_item(index)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_delete_item(index)

func _use_item(index: int) -> void:
	var item = GameState.inventory.items[index]

	if item.name == "Coin":
		pass  
	elif item.name == "Food":
	
		get_parent().get_parent().heal(10)  
		GameState.inventory.remove_item(index, 1)
		_refresh()
	

func _delete_item(index: int) -> void:
	var item = GameState.inventory.items[index]

	GameState.inventory.remove_item(index, 1)
	_refresh()

	if item.name == "Coin":
		var coin = coin_scene.instantiate()
		coin.get_node("CollisionArea").is_kicked = true
		coin.global_position = player.global_position
		get_tree().current_scene.add_child(coin)
