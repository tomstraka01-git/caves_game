extends Node2D

@onready var main = $".."
@onready var anim_sprite = $"../AnimatedSprite2D"
@onready var error_sound = $"../ErrorSound"
@onready var click_sound = $"../EnterSound"
@onready var error_label = $"../ErrorLabel"
@onready var area = self
@onready var interact_label = $"../Interact"

var level_index: int = 0
var target_scene: String = ""
var transitioning := false
var fade: ColorRect
var player_inside := false
var level_text = "Level: 0"
var _error_label_tween: Tween = null

func _ready():
    interact_label.visible = false
    error_label.text = "You do not have\nthis level unlocked yet"
    error_label.modulate.a = 0.0
    error_label.visible = true
    level_text = main.level_text
    level_index = main.level_index
    target_scene = main.scene
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
    anim_sprite.play("idle")
    anim_sprite.modulate = Color(1, 1, 1, 1)
    var canvas = CanvasLayer.new()
    add_child(canvas)
    fade = ColorRect.new()
    canvas.add_child(fade)
    fade.anchor_left = 0
    fade.anchor_top = 0
    fade.anchor_right = 1
    fade.anchor_bottom = 1
    fade.color = Color.BLACK
    fade.modulate = Color(1, 1, 1, 0)

func _is_unlocked() -> bool:
    if level_index == 0:
        return true
    return GameState.level_completed[level_index - 1]

func _process(_delta):
    if player_inside and Input.is_action_just_pressed("interact"):
        if _is_unlocked():
            anim_sprite.play("click")
            _enter_cave()
        else:
            _play_locked_feedback()

func _on_body_entered(body):
    if body.is_in_group("character"):
        player_inside = true
        anim_sprite.play("click")
        interact_label.visible = true

func _on_body_exited(body):
    if body.is_in_group("character"):
        player_inside = false
        anim_sprite.play("idle")
        interact_label.visible = false

func _play_locked_feedback() -> void:
    error_sound.play()
    _show_error_label()
    _shake_node(error_label)

func _show_error_label() -> void:
    
    if _error_label_tween and _error_label_tween.is_valid():
        _error_label_tween.kill()

    _error_label_tween = create_tween()
  
    _error_label_tween.tween_property(error_label, "modulate:a", 1.0, 0.15)
 
    _error_label_tween.tween_interval(1.0)

    _error_label_tween.tween_property(error_label, "modulate:a", 0.0, 0.3)
    await _error_label_tween.finished
    interact_label.visible = true

func _shake_node(node: Node) -> void:
    interact_label.visible = false
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
    
func _enter_cave():
    if transitioning:
        return
    anim_sprite.modulate = Color(1, 1, 1, 1)
    interact_label.visible = false
    transitioning = true
    click_sound.pitch_scale = 0.8
    click_sound.play()
    anim_sprite.play("fade")
    var tween = create_tween()
    tween.tween_property(fade, "modulate:a", 1.0, 0.8)
    await tween.finished
    await get_tree().create_timer(0.2).timeout
    if target_scene != "":
        get_tree().change_scene_to_file(target_scene)
    else:
        push_error("No target_scene set on door with level_index: " + str(level_index))
