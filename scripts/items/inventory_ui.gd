extends Panel

@onready var item_grid: GridContainer = $VBoxContainer/ItemGrid

const SLOT_SIZE = 96
const COLUMNS = 5
const ROWS = 4
var coin_scene = preload("res://scenes/item_scenes/coin.tscn")
var key_scene = preload("res://scenes/item_scenes/key.tscn")
var potion_health_scene = preload("res://scenes/item_scenes/potion_health.tscn")
var potion_damage_scene = preload("res://scenes/item_scenes/potion_damage.tscn")
var potion_stamina_scene = preload("res://scenes/item_scenes/potion_stamina.tscn")
var amulet_health_scene = preload("res://scenes/item_scenes/amulet_health.tscn")
var amulet_stamina_scene = preload("res://scenes/item_scenes/amulet_stamina.tscn")
var amulet_damage_scene = preload("res://scenes/item_scenes/amulet_damage.tscn")

var health_added = randi_range(10, 30)
var damage_added = randi_range(5, 10)
var stamina_added = randi_range(15, 30)

var health_amulet_equipped = false
var damage_amulet_equipped = false


@onready var player = get_parent().get_parent()

const EQUIP_SLOT_NAMES = ["Slot1", "Slot2", "Slot3", "Slot4", "Slot5"]

const EQUIPPABLE_NAMES: Array = [
    "AmuletHealth",
    "AmuletDamage",
    "AmuletStamina",
]

var equip_items: Array = []
var equip_counts: Array = []

var selected_inv_index: int = -1

var equip_panel: Panel
var equip_slot_wrappers: Array = []

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

    $VBoxContainer.set_anchors_preset(Control.PRESET_FULL_RECT)

    for i in EQUIP_SLOT_NAMES.size():
        equip_items.append(null)
        equip_counts.append(0)

    _build_equip_panel()
    hide()

func _build_equip_panel() -> void:
    var gap = 12
    var equip_panel_width = SLOT_SIZE + 16
    var equip_panel_height = EQUIP_SLOT_NAMES.size() * (SLOT_SIZE + 4) + 16 + 48

    equip_panel = Panel.new()
    equip_panel.size = Vector2(equip_panel_width, equip_panel_height)
    equip_panel.position = Vector2(size.x + gap, 0)
    equip_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(equip_panel)

    var title = Label.new()
    title.text = "Equipment"
    title.position = Vector2(8, 8)
    title.size = Vector2(equip_panel_width - 16, 32)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 20)
    equip_panel.add_child(title)

    equip_slot_wrappers.clear()

    for i in EQUIP_SLOT_NAMES.size():
        var row = HBoxContainer.new()
        row.position = Vector2(8, 48 + i * (SLOT_SIZE + 4))
        row.size = Vector2(equip_panel_width - 16, SLOT_SIZE)
        equip_panel.add_child(row)

        var wrapper = Control.new()
        wrapper.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
        wrapper.mouse_filter = Control.MOUSE_FILTER_STOP

        var slot = Panel.new()
        slot.name = "Slot"
        slot.size = Vector2(SLOT_SIZE, SLOT_SIZE)
        slot.clip_contents = true
        slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
        wrapper.add_child(slot)

        var idx = i
        wrapper.gui_input.connect(func(event): _on_equip_slot_clicked(event, idx))

        row.add_child(wrapper)
        equip_slot_wrappers.append(wrapper)

    _refresh_equip_panel()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_inventory"):
        if visible:
            _clear_selection()
            hide()
            equip_panel.hide()
        else:
            _refresh()
            _refresh_equip_panel()
            show()
            equip_panel.show()

func _clear_selection() -> void:
    selected_inv_index = -1

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

        if i == selected_inv_index:
            var hl = StyleBoxFlat.new()
            hl.bg_color = Color(1, 1, 0, 0.35)
            hl.border_width_left = 3
            hl.border_width_right = 3
            hl.border_width_top = 3
            hl.border_width_bottom = 3
            hl.border_color = Color(1, 1, 0, 1)
            slot.add_theme_stylebox_override("panel", hl)

        wrapper.add_child(slot)

        if i < GameState.inventory.items.size():
            var item = GameState.inventory.items[i]
            var count = GameState.inventory.stack_counts[i]

            var icon = TextureRect.new()
            icon.texture = item.texture
            icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            icon.size = Vector2(SLOT_SIZE, SLOT_SIZE)
            icon.position = Vector2.ZERO
            icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
            slot.add_child(icon)

            if count > 1:
                var label = Label.new()
                label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
                label.text = str(count)
                label.size = Vector2(SLOT_SIZE, 12)
                label.position = Vector2(-6, SLOT_SIZE - 36).round()
                label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
                label.add_theme_font_size_override("font_size", 32)
                label.mouse_filter = Control.MOUSE_FILTER_IGNORE
                wrapper.add_child(label)

            var idx = i
            wrapper.gui_input.connect(func(event): _on_slot_clicked(event, idx))
            wrapper.tooltip_text = item.name + "\n" + item.description

        item_grid.add_child(wrapper)

func _refresh_equip_panel() -> void:
    for i in equip_slot_wrappers.size():
        var wrapper = equip_slot_wrappers[i]
        var slot = wrapper.get_node("Slot")

        for child in slot.get_children():
            child.queue_free()
        for child in wrapper.get_children():
            if child is Label:
                child.queue_free()
        slot.remove_theme_stylebox_override("panel")

        if equip_items[i] != null:
            var item = equip_items[i]
            var count = equip_counts[i]

            var icon = TextureRect.new()
            icon.texture = item.texture
            icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            icon.size = Vector2(SLOT_SIZE, SLOT_SIZE)
            icon.position = Vector2.ZERO
            icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
            slot.add_child(icon)

            if count > 1:
                var label = Label.new()
                label.text = str(count)
                label.size = Vector2(SLOT_SIZE, 12)
                label.position = Vector2(-6, SLOT_SIZE - 36).round()
                label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
                label.add_theme_font_size_override("font_size", 32)
                label.mouse_filter = Control.MOUSE_FILTER_IGNORE
                wrapper.add_child(label)

            wrapper.tooltip_text = item.name + "\n" + item.description
        else:
            wrapper.tooltip_text = EQUIP_SLOT_NAMES[i] + " (empty)"

func _on_slot_clicked(event: InputEvent, index: int) -> void:
    if not event is InputEventMouseButton or not event.pressed:
        return
    if index >= GameState.inventory.items.size():
        return

    if event.button_index == MOUSE_BUTTON_LEFT:
        if selected_inv_index == index:
            _use_item(index)
            _clear_selection()
        else:
            selected_inv_index = index
        _refresh()

    elif event.button_index == MOUSE_BUTTON_RIGHT:
        _clear_selection()
        _delete_item(index)

func _on_equip_slot_clicked(event: InputEvent, index: int) -> void:
    if not event is InputEventMouseButton or not event.pressed:
        return

    if event.button_index == MOUSE_BUTTON_LEFT:
        if selected_inv_index >= 0 and selected_inv_index < GameState.inventory.items.size():
            var item = GameState.inventory.items[selected_inv_index]
            var count = GameState.inventory.stack_counts[selected_inv_index]

            if not EQUIPPABLE_NAMES.has(item.name):
                _clear_selection()
                _refresh()
                return

            if equip_items[index] != null:
                _call_unequip(equip_items[index])
                GameState.inventory.add_item(equip_items[index], equip_counts[index])

            equip_items[index] = item
            equip_counts[index] = count
            GameState.inventory.remove_item(selected_inv_index, count)
            _call_equip(item)

            _clear_selection()
            _refresh()
            _refresh_equip_panel()

    elif event.button_index == MOUSE_BUTTON_RIGHT:
        if equip_items[index] != null:
            _call_unequip(equip_items[index])
            GameState.inventory.add_item(equip_items[index], equip_counts[index])
            equip_items[index] = null
            equip_counts[index] = 0
            _refresh()
            _refresh_equip_panel()

func _call_equip(item: Item) -> void:
    match item.name:
        "AmuletHealth":
            _on_equip_amulet_health(item)
        "AmuletDamage":
            _on_equip_amulet_damage(item)
        "AmuletStamina":
            _on_equip_amulet_stamina(item)

func _call_unequip(item: Item) -> void:
    match item.name:
        "AmuletHealth":
            _on_unequip_amulet_health(item)
        "AmuletDamage":
            _on_unequip_amulet_damage(item)
        "AmuletStamina":
            _on_unequip_amulet_stamina(item)

func _use_item(index: int) -> void:
    var item = GameState.inventory.items[index]
    if item.name == "Coin":
        pass
    elif item.name == "PotionDamage":
        get_parent().get_parent().use_damage_potion(30, 5)
        GameState.inventory.remove_item(index, 1)
        _refresh()
    elif item.name == "PotionHealth":
        get_parent().get_parent().heal_player(20)
        GameState.inventory.remove_item(index, 1)
        _refresh()
    elif item.name == "PotionStamina":
        get_parent().get_parent().use_stamina_potion(20)
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
      
    elif item.name == "Key":
        var key = key_scene.instantiate()
        key.get_node("CollisionArea").is_kicked = true
        key.global_position = player.global_position
        get_tree().current_scene.add_child(key)
    
    elif item.name == "PotionHealth":
        var potion_health = potion_health_scene.instantiate()
        potion_health.get_node("CollisionArea").is_kicked = true
        potion_health.global_position = player.global_position
        get_tree().current_scene.add_child(potion_health)
      
    elif item.name == "PotionDamage":
        var potion_damage = potion_damage_scene.instantiate()
        potion_damage.get_node("CollisionArea").is_kicked = true
        potion_damage.global_position = player.global_position
        get_tree().current_scene.add_child(potion_damage)
      
    elif item.name == "PotionStamina":
        var potion_stamina = potion_stamina_scene.instantiate()
        potion_stamina.get_node("CollisionArea").is_kicked = true
        potion_stamina.global_position = player.global_position
        get_tree().current_scene.add_child(potion_stamina)
       
    elif item.name == "AmuletHealth":
        var amulet_health = amulet_health_scene.instantiate()
        amulet_health.get_node("CollisionArea").is_kicked = true
        amulet_health.global_position = player.global_position
        get_tree().current_scene.add_child(amulet_health)
 
    elif item.name == "AmuletStamina":
        var amulet_stamina = amulet_stamina_scene.instantiate()
        amulet_stamina.get_node("CollisionArea").is_kicked = true
        amulet_stamina.global_position = player.global_position
        get_tree().current_scene.add_child(amulet_stamina)
    
    elif item.name == "AmuletDamage":
        var amulet_damage = amulet_damage_scene.instantiate()
        amulet_damage.get_node("CollisionArea").is_kicked = true
        amulet_damage.global_position = player.global_position
        get_tree().current_scene.add_child(amulet_damage)      
             
        
func _on_equip_amulet_health(item: Item) -> void:

    player.max_health += health_added
    player.progress_bar._amulet_health(health_added, player.player_health)
    health_amulet_equipped = true
    var percent = int((float(health_added) / float(player.max_health)) * 100)
    item.description = "Adds " + str(percent) + "% more health"
 
func _on_unequip_amulet_health(item: Item) -> void:
    player.max_health -= health_added
    player.player_health = min(player.player_health, player.max_health)
    player.progress_bar._amulet_health(-health_added, player.player_health)
    health_amulet_equipped = false
      
func _on_equip_amulet_damage(item: Item) -> void:
    player.damage_bonus += damage_added
    damage_amulet_equipped = true
    item.description = "Adds " + str(damage_added) + " more damage"

func _on_unequip_amulet_damage(item: Item) -> void:
    player.damage_bonus -= damage_added
    damage_amulet_equipped = true

func _on_equip_amulet_stamina(item: Item) -> void:
    player.ui.max_stamina += stamina_added
    player.ui.stamina_bar.max_value = player.ui.max_stamina
    player.ui.current_stamina += stamina_added

func _on_unequip_amulet_stamina(item: Item) -> void:
    player.ui.max_stamina -= stamina_added
    player.ui.stamina_bar.max_value = player.ui.max_stamina
    player.ui.current_stamina = min(player.ui.current_stamina, player.ui.max_stamina)
    
