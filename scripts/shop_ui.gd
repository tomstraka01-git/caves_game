extends Panel

@onready var shop_grid: GridContainer = $VBoxContainer/ShopGrid

const SLOT_SIZE = 48
const COLUMNS = 3

var shop_data: ShopData

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    shop_grid.columns = COLUMNS
    shop_grid.add_theme_constant_override("h_separation", 8)
    shop_grid.add_theme_constant_override("v_separation", 8)
    $VBoxContainer.set_anchors_preset(Control.PRESET_FULL_RECT)
    size = Vector2(300, 300)
    var screen = get_viewport().get_visible_rect().size
    position = (screen / 2 - size / 2).round()
    hide()

func open(data: ShopData) -> void:
    if data == null:
        print("shop_data not assigned!")
        return
    shop_data = data
    _refresh()
    show()

func close() -> void:
    hide()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        close()

func _refresh() -> void:
    if shop_data == null:
        return
    for child in shop_grid.get_children():
        child.queue_free()

    var coins = GameState.inventory.get_item_count("Coin")

    for i in shop_data.items.size():
        var shop_item = shop_data.items[i]
        var can_afford = coins >= shop_item.price

        var wrapper = Control.new()
        wrapper.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE + 20)
        wrapper.mouse_filter = Control.MOUSE_FILTER_STOP

        var slot = Panel.new()
        slot.size = Vector2(SLOT_SIZE, SLOT_SIZE)
        slot.clip_contents = true
        slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
       

        var icon = TextureRect.new()
        icon.texture = shop_item.item.texture
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.size = Vector2(SLOT_SIZE, SLOT_SIZE)
        icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        slot.add_child(icon)

        var price_label = Label.new()
        price_label.text = str(shop_item.price) + "c"
        price_label.size = Vector2(SLOT_SIZE, 16)
        price_label.position = Vector2(0, SLOT_SIZE + 2)
        price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        price_label.add_theme_font_size_override("font_size", 10)
        price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
        price_label.modulate = Color.WEB_GREEN if can_afford else Color(1.0, 0.4, 0.4)

        wrapper.tooltip_text = shop_item.item.name + "\n" + shop_item.item.description + "\nCost: " + str(shop_item.price) + " coins"

        var idx = i
        wrapper.gui_input.connect(func(event):
            if event is InputEventMouseButton and event.pressed:
                if event.button_index == MOUSE_BUTTON_LEFT:
                    _try_buy(idx)
        )

        wrapper.add_child(slot)
        wrapper.add_child(price_label)
        shop_grid.add_child(wrapper)

func _try_buy(index: int) -> void:
    var shop_item = shop_data.items[index]
    var coins = GameState.inventory.get_item_count("Coin")

    if coins >= shop_item.price:
        for i in GameState.inventory.items.size():
            if GameState.inventory.items[i].name == "Coin":
                GameState.inventory.remove_item(i, shop_item.price)
                break
        GameState.inventory.add_item(shop_item.item, 1)
        _flash_success(index)
    else:
        _flash_error(index)

func _flash_success(index: int) -> void:
    var slot = shop_grid.get_child(index).get_child(0)
    var tween = create_tween()
    tween.tween_property(slot, "modulate", Color.WHITE, 0.1)
    tween.tween_property(slot, "modulate", Color.GREEN, 0.1)
    tween.tween_property(slot, "modulate", Color.WHITE, 0.1)
    await tween.finished
    _refresh() 

func _flash_error(index: int) -> void:
    var slot = shop_grid.get_child(index).get_child(0)
    var tween = create_tween()
    tween.tween_property(slot, "modulate", Color.RED, 0.1)
    tween.tween_property(slot, "modulate", Color.WHITE, 0.1)
    await tween.finished
