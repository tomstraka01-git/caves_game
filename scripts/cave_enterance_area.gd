extends Area2D

@export var target_scene: String = "res://scenes/level_0.tscn"
@onready var anim_sprite = $"../AnimatedSprite2D"

var inside_levels = false
var transitioning := false
var fade: ColorRect
var player_inside := false

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    var current_scene = get_tree().current_scene.scene_file_path
    anim_sprite.play("idle")
    if current_scene == "res://scenes/levels_cave.tscn":
       inside_levels = true
 
    var canvas = CanvasLayer.new()
    add_child(canvas)

    fade = ColorRect.new()
    canvas.add_child(fade)

    fade.anchor_left = 0
    fade.anchor_top = 0
    fade.anchor_right = 1
    fade.anchor_bottom = 1

    fade.offset_left = 0
    fade.offset_top = 0
    fade.offset_right = 0
    fade.offset_bottom = 0

    fade.color = Color.BLACK
    fade.modulate = Color(1,1,1,0)

func _process(_delta):
    if player_inside and Input.is_action_just_pressed("interact"):
        anim_sprite.play("click")
        _enter_cave()

func _on_body_entered(body):
    if body.is_in_group("character"):
        player_inside = true
        anim_sprite.play("click")

func _on_body_exited(body):
    if body.is_in_group("character"):
        player_inside = false
        anim_sprite.play("idle")

func _enter_cave():
    if transitioning:
        return

    transitioning = true
    anim_sprite.play("fade")
    var tween = create_tween()
    tween.tween_property(fade, "modulate:a", 1.0, 0.8)

    await tween.finished
    await get_tree().create_timer(0.2).timeout

    if target_scene != "":
        if inside_levels == false:
            get_tree().change_scene_to_file(target_scene)
        else:
            get_tree().change_scene_to_file("res://scenes/base.tscn")
    else:
        push_error("No target_scene")
