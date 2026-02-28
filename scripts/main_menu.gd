extends Control

@onready var start_button = $CenterContainer/VBoxContainer/Start
@onready var quit_button = $CenterContainer/VBoxContainer/Quit
@onready var click_sound = $CanvasLayer/AudioStreamPlayer2D

var current_pitch := 1.0
var pitch_step := 0.1
var max_pitch := 2.0


func play_click():
    current_pitch += pitch_step
    
    if current_pitch > max_pitch:
        current_pitch = 1.0   
    
    click_sound.pitch_scale = current_pitch
    click_sound.play()


func _on_start_pressed() -> void:
    play_click()
    get_tree().change_scene_to_file("res://scenes/levels.tscn")


func _on_quit_pressed() -> void:
    play_click()
    get_tree().quit()


func _on_start_mouse_entered() -> void:
    play_click()


func _on_quit_mouse_entered() -> void:
    play_click()
