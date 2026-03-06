extends Control

@onready var level0 = $Levels/Level0
@onready var level1 = $Levels/Level1
@onready var level2 = $Levels/Level2
@onready var level3 = $Levels/Level3
@onready var left_node = $Left_Node
@onready var right_node = $Right_Node
@onready var levels = $Levels
@onready var label = $Cave_Label
@onready var click_sound = $CanvasLayer/AudioStreamPlayer2D
@onready var error_sound = $CanvasLayer/ErrorSound
@onready var fade: ColorRect = $CanvasLayer/Fade

@onready var lock0 = $Levels/Level0/Lock
@onready var lock1 = $Levels/Level1/Lock
@onready var lock2 = $Levels/Level2/Lock
@onready var lock3 = $Levels/Level3/Lock

var center = 490
var difference = 700
var current_level = 0
var max_level = 3
var is_animating = false
var transitioning = false
var fade_time := 0.5

func _is_unlocked(index: int) -> bool:
    if index == 0:
        return true
    return GameState.level_completed[index - 1]

func _get_level_button(index: int) -> Button:
    match index:
        0: return level0
        1: return level1
        2: return level2
        3: return level3
    return null

func _get_lock(index: int) -> Node:
    match index:
        0: return lock0
        1: return lock1
        2: return lock2
        3: return lock3
    return null

func _ready() -> void:
    level0.position = Vector2(490, 339)
    level1.position = Vector2(center + difference, 339)
    level2.position = Vector2(center + difference * 2, 339)
    level3.position = Vector2(center + difference * 3, 339)
    _update_arrows()
    _update_locks()
    fade.modulate.a = 0.0
    fade.visible = true

func _update_locks() -> void:
    lock0.visible = not _is_unlocked(0)
    lock1.visible = not _is_unlocked(1)
    lock2.visible = not _is_unlocked(2)
    lock3.visible = not _is_unlocked(3)

func _update_arrows() -> void:
    right_node.visible = current_level < max_level
    left_node.visible = current_level > 0

func _slide_to(target_x: float) -> void:
    if is_animating:
        return
    is_animating = true
    var tween = create_tween()
    tween.tween_property(levels, "position:x", target_x, 0.4)\
        .set_trans(Tween.TRANS_CUBIC)\
        .set_ease(Tween.EASE_OUT)
    tween.tween_callback(func():
        is_animating = false
        _update_locks()
    )





func _play_locked_feedback() -> void:
    error_sound.play()
    var btn = _get_level_button(current_level)
    var lck = _get_lock(current_level)
    _shake_node(btn)
    _shake_node(lck)

func _shake_node(node: Node) -> void:
    var original_x: float
    if node is Control:
        original_x = (node as Control).position.x
    elif node is Node2D:
        original_x = (node as Node2D).position.x
    else:
        return
    var tween = create_tween()
    tween.tween_property(node, "position:x", original_x + 10, 0.05)
    tween.tween_property(node, "position:x", original_x - 10, 0.05)
    tween.tween_property(node, "position:x", original_x + 8,  0.05)
    tween.tween_property(node, "position:x", original_x - 8,  0.05)
    tween.tween_property(node, "position:x", original_x + 4,  0.04)
    tween.tween_property(node, "position:x", original_x,      0.04)

func _on_level_0_pressed() -> void:
    if _is_unlocked(0): _play_click_and_fade("res://scenes/level_0.tscn")
    else: _play_locked_feedback()

func _on_level_1_pressed() -> void:
    if _is_unlocked(1): _play_click_and_fade("res://scenes/level_1.tscn")
    else: _play_locked_feedback()

func _on_level_2_pressed() -> void:
    if _is_unlocked(2): _play_click_and_fade("res://scenes/level_2.tscn")
    else: _play_locked_feedback()

func _on_level_3_pressed() -> void:
    if _is_unlocked(3): _play_click_and_fade("res://scenes/level_3.tscn")
    else: _play_locked_feedback()

func _on_left_pressed() -> void:
    if current_level < max_level and not is_animating:
        current_level += 1
        _slide_to(levels.position.x - difference)
        _update_arrows()
        _play_click()

func _on_right_pressed() -> void:
    if current_level > 0 and not is_animating:
        current_level -= 1
        _slide_to(levels.position.x + difference)
        _update_arrows()
        _play_click()

func _play_click() -> void:
    click_sound.pitch_scale = 0.8
    click_sound.play()

func _play_click_and_fade(scene_path: String) -> void:
    if transitioning:
        return
    transitioning = true
    click_sound.pitch_scale = 0.8
    click_sound.play()
    var tween = create_tween()
    tween.tween_property(fade, "modulate:a", 1.0, fade_time)
    tween.finished.connect(func():
        get_tree().create_timer(0.2).timeout.connect(func():
            get_tree().change_scene_to_file(scene_path)
        )
    )

func _on_left_mouse_entered() -> void:  _play_click()
func _on_right_mouse_entered() -> void: _play_click()
func _on_level_0_mouse_entered() -> void: _play_click()
func _on_level_1_mouse_entered() -> void: _play_click()
func _on_level_2_mouse_entered() -> void: _play_click()
func _on_level_3_mouse_entered() -> void: _play_click()
func _on_back_pressed() -> void: _play_click_and_fade("res://scenes/main_menu.tscn")
func _on_back_mouse_entered() -> void: _play_click()
