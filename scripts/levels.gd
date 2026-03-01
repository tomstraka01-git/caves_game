extends Control

@onready var level0 = $Levels/Level0 
@onready var level1 = $Levels/Level1
@onready var level2 = $Levels/Level2
@onready var left_node = $Left_Node
@onready var right_node = $Right_Node
@onready var levels = $Levels
@onready var label = $Cave_Label


@onready var click_sound = $CanvasLayer/AudioStreamPlayer2D
@onready var fade: ColorRect = $CanvasLayer/Fade

var center = 490
var difference = 700
var current_level = 0
var max_level = 2
var is_animating = false
var transitioning = false
var fade_time := 0.5

func _ready() -> void:
    level0.position = Vector2(490, 339)
    level1.position = Vector2(center + difference, 339)
    level2.position = Vector2(center + difference * 2, 339)
    _update_arrows()

    fade.modulate.a = 0.0
    fade.visible = true



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
    tween.tween_callback(func(): is_animating = false)


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



func _on_level_0_pressed() -> void:
    _play_click_and_fade("res://scenes/level_0.tscn")
func _on_level_1_pressed() -> void:
    _play_click_and_fade("res://scenes/level_1.tscn")
func _on_level_2_pressed() -> void:
    _play_click_and_fade("res://scenes/level_2.tscn")



func _play_click():
   
    click_sound.pitch_scale = 0.8
    click_sound.play()


func _play_click_and_fade(scene_path: String):
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





func _on_left_mouse_entered() -> void:
    _play_click()


func _on_right_mouse_entered() -> void:
    _play_click()


func _on_level_0_mouse_entered() -> void:
    _play_click()


func _on_level_1_mouse_entered() -> void:
    _play_click()


func _on_level_2_mouse_entered() -> void:
    _play_click()


func _on_back_pressed() -> void:
    
    _play_click_and_fade("res://scenes/main_menu.tscn")
    


func _on_back_mouse_entered() -> void:
    _play_click()
