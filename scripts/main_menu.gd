extends Control

@onready var start_button = $CenterContainer/VBoxContainer/Start
@onready var quit_button = $CenterContainer/VBoxContainer/Quit

# Called when the node enters the scene tree for the first time.



# Called every frame. 'delta' is the elapsed time since the previous frame.



func _on_start_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/levels.tscn")


func _on_quit_pressed() -> void:
    get_tree().quit()
