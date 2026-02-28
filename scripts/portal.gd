extends Area2D

@export var fade_time: float = 0.5
@onready var portal = $Sprite2D
var teleporting := false
var fade: ColorRect
func _process(delta: float) -> void:
    portal.rotate(1 * delta)

func _ready():
    body_entered.connect(_on_body_entered)

    # Get fade AFTER scene is ready
    var current_scene = get_tree().current_scene
    fade = current_scene.get_node("CanvasLayer/Fade")

    # Make sure fade starts transparent
    fade.modulate.a = 0.0
    fade.visible = true


func _on_body_entered(body):
    if body.is_in_group("character") and not teleporting:
        teleporting = true
        await fade_and_change_scene()


func fade_and_change_scene():

    var current_scene = get_tree().current_scene
    if current_scene == null:
        return

    # Fade OUT
    var tween = create_tween()
    tween.tween_property(fade, "modulate:a", 1.0, fade_time)
    await tween.finished

    await get_tree().create_timer(0.2).timeout

    var scene_path = current_scene.scene_file_path

    if scene_path == "res://scenes/level_0.tscn":
        get_tree().change_scene_to_file("res://scenes/level_1.tscn")

    elif scene_path == "res://scenes/level_1.tscn":
        get_tree().change_scene_to_file("res://scenes/level_2.tscn")
