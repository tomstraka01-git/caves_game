extends Control


@onready var level0 = $Level0 
@onready var level1 = $Level1
@onready var label = $Cave_Label

var center = 490
var difference = 700
func _ready() -> void:
    level0.position = Vector2(490, 339)
    level1.position = Vector2(center + difference, 339)
   

func _on_left_pressed() -> void:
    pass # Replace with function body.


func _on_right_pressed() -> void:
    pass # Replace with function body.


func _on_level_0_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/main_game.tscn")
