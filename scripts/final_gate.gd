extends Node2D

var gate_max_value = 100
@onready var gate = $Gate
@onready var gate_bars = $TextureProgressBarGate

@onready var enter_sprite = $EnterSprite
@onready var exit_sprite = $ExitSprite
@onready var label = $Label
@onready var audio_player = $ErrorSound

@export var is_enter: bool = true
@export var required_key_item: String = "Key"
@export var soul_item: String = "SoulItem"
@export var enter_scene: String = ""
@export var exit_scene: String = ""
@export var fade_time: float = 2.0

var is_inside = false
var gate_fall_time = 3.0
var gate_moving = false
var gate_open = false
var label_tween: Tween = null
var fade: ColorRect

func _ready() -> void:
    gate_bars.visible = true
    gate.visible = true
 
    gate_bars.max_value = gate_max_value
    gate_bars.value = gate_max_value
    label.visible = false

    if is_enter:
        enter_sprite.visible = true
        exit_sprite.visible = false
    else:
        enter_sprite.visible = false
        exit_sprite.visible = true

    var current_scene = get_tree().current_scene
    fade = current_scene.get_node("CanvasLayer/Fade")
    fade.modulate.a = 0.0
    fade.visible = true

func _input(event):
    if !is_inside or gate_moving:
        return

    if event.is_action_pressed("interact"):
        if is_enter:
            _try_enter()
        else:
            _try_exit()

func _try_enter() -> void:
    if not _has_item(required_key_item):
        animate_error_label("You need the " + required_key_item + " to enter!")
        return
    _confirm_entry()

func _try_exit() -> void:
    if not _has_item(soul_item):
        animate_error_label("You need the " + soul_item + " to pass!")
        return
    await up_gate()
    await fade_and_change_scene(exit_scene)

func _confirm_entry() -> void:
    var dialog = ConfirmationDialog.new()
    dialog.title = "Enter Boss Area"
    dialog.dialog_text = "Are you sure you want to enter the final boss area?\nThis will consume your " + required_key_item + "."
    add_child(dialog)
    dialog.popup_centered()

    dialog.confirmed.connect(func():
        _consume_item(required_key_item)
        dialog.queue_free()
        _do_enter()
    )
    dialog.canceled.connect(func():
        dialog.queue_free()
    )

func _do_enter() -> void:
    await up_gate()
    await fade_and_change_scene(enter_scene)

func fade_and_change_scene(target_scene: String) -> void:
    if target_scene == "":
        return
    var tween = create_tween()
    tween.tween_property(fade, "modulate:a", 1.0, fade_time)
    await tween.finished
    await get_tree().create_timer(0.3).timeout
    get_tree().change_scene_to_file(target_scene)

func animate_error_label(message: String) -> void:
    if label_tween != null and label_tween.is_running():
        label_tween.kill()

    label.text = message
    label.modulate.a = 1.0
    label.visible = true
    audio_player.play()

    var original_pos = label.position
    label_tween = create_tween()
    label_tween.tween_property(label, "position:x", original_pos.x + 8, 0.05)
    label_tween.tween_property(label, "position:x", original_pos.x - 8, 0.05)
    label_tween.tween_property(label, "position:x", original_pos.x + 6, 0.05)
    label_tween.tween_property(label, "position:x", original_pos.x - 6, 0.05)
    label_tween.tween_property(label, "position:x", original_pos.x, 0.05)
    await label_tween.finished

    await get_tree().create_timer(1.0).timeout
    label_tween = create_tween()
    label_tween.tween_property(label, "modulate:a", 0.0, 0.5)
    await label_tween.finished
    label.visible = false

func _has_item(item_name: String) -> bool:
    for item in GameState.inventory.items:
        if item.name == item_name:
            return true
    return false

func _consume_item(item_name: String) -> void:
    for i in GameState.inventory.items.size():
        if GameState.inventory.items[i].name == item_name:
            GameState.inventory.remove_item(i, 1)
            break

func up_gate():
    gate_moving = true
    var tween = create_tween()
    tween.tween_property(gate_bars, "value", 0, gate_fall_time)
    await tween.finished
  
    gate_open = true
    gate_moving = false

func lower_gate():
    gate_moving = true
    var tween = create_tween()
    tween.tween_property(gate_bars, "value", gate_max_value, gate_fall_time)
    await tween.finished
  
    gate_open = false
    gate_moving = false

func _on_area_2d_body_entered(body: Node2D) -> void:
    if body.is_in_group("character"):
        is_inside = true

func _on_area_2d_body_exited(body: Node2D) -> void:
    if body.is_in_group("character"):
        is_inside = false
