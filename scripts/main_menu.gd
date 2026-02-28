extends Control

@export var fade_time: float = 0.5

@onready var click_sound = $CanvasLayer/AudioStreamPlayer2D
@onready var fade: ColorRect = $CanvasLayer/Fade

var transitioning := false


func _ready():
    fade.modulate.a = 0.0


func _on_start_pressed() -> void:
    if transitioning:
        return
    transitioning = true
    await play_click_and_fade("res://scenes/levels.tscn")


func _on_quit_pressed() -> void:
    if transitioning:
        return
    transitioning = true
    await play_click_and_fade(null)


func _on_start_mouse_entered() -> void:
    play_hover()


func _on_quit_mouse_entered() -> void:
    play_hover()



func play_hover():
    click_sound.pitch_scale = 0.8
    click_sound.play()



func play_click_and_fade(scene_path):

    click_sound.pitch_scale = 0.8
    click_sound.play()

    var tween = create_tween()
    tween.tween_property(fade, "modulate:a", 1.0, fade_time)
    await tween.finished

    await get_tree().create_timer(0.2).timeout

    if scene_path != null:
        get_tree().change_scene_to_file(scene_path)
    else:
        get_tree().quit()
