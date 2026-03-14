extends Area2D

@export var fade_time: float = 2

@onready var interact_label = $Interact

@onready var anim_sprite = $AnimatedSprite2D
var teleporting := false
var fade: ColorRect
var player_inside: bool = false
var player_ref: Node = null

func _process(delta: float) -> void:
    
    
    if player_inside and Input.is_action_just_pressed("interact"):
        _try_enter_portal()

func _ready():
    interact_label.visible = false
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    var current_scene = get_tree().current_scene
    fade = current_scene.get_node("CanvasLayer/Fade")
    fade.modulate.a = 0.0
    fade.visible = true
    
func _on_body_entered(body):
    if body.is_in_group("character"):
        player_inside = true
        player_ref = body
        anim_sprite.play("click")
        interact_label.visible = true

func _on_body_exited(body):
    if body.is_in_group("character"):
        player_inside = false
        player_ref = null
        anim_sprite.play("idle")
        interact_label.visible = false
       

func _try_enter_portal():
    if teleporting or player_ref == null:
        return
    var key_count = GameState.inventory.get_item_count("Key") 
    if key_count >= 1:
        teleporting = true
  
        for i in GameState.inventory.items.size():
            if GameState.inventory.items[i].name == "Key":
                GameState.inventory.remove_item(i, 1)
                break
        await fade_and_change_scene()
    else:
        $NotEnoughCoinsSound.play()
        animate_error_label()

var _error_tween: Tween = null

func animate_error_label():
    var label = $Label


    if _error_tween and _error_tween.is_valid():
        _error_tween.kill()

   
    label.position = label.position  
    label.modulate.a = 1.0
    label.visible = true
    interact_label.visible = false
    label.text = "You need a key to unlock"

    var original_pos = label.position

    _error_tween = create_tween()
    _error_tween.tween_property(label, "position:x", original_pos.x + 8, 0.05)
    _error_tween.tween_property(label, "position:x", original_pos.x - 8, 0.05)
    _error_tween.tween_property(label, "position:x", original_pos.x + 6, 0.05)
    _error_tween.tween_property(label, "position:x", original_pos.x - 6, 0.05)
    _error_tween.tween_property(label, "position:x", original_pos.x,     0.05)


    _error_tween.tween_interval(1.0)
    _error_tween.tween_property(label, "modulate:a", 0.0, 0.5)

    await _error_tween.finished


    if _error_tween and not _error_tween.is_running():
        label.visible = false
        interact_label.visible = true

func fade_and_change_scene():
    
    interact_label.visible = false
    var current_scene = get_tree().current_scene
    if current_scene == null:
        return
    anim_sprite.play("fade")
    $DoorEnter.play()
    var tween = create_tween()
    tween.tween_property(fade, "modulate:a", 1.0, fade_time)
    await tween.finished
    await get_tree().create_timer(0.3).timeout

    var scene_path = current_scene.scene_file_path
    if scene_path == "res://scenes/level_0.tscn":
        GameState.complete_level(0)
        get_tree().change_scene_to_file("res://scenes/level_1.tscn")
    elif scene_path == "res://scenes/level_1.tscn":
        GameState.complete_level(1)
        get_tree().change_scene_to_file("res://scenes/level_2.tscn")
    elif scene_path == "res://scenes/level_2.tscn":
        GameState.complete_level(2)
        get_tree().change_scene_to_file("res://scenes/level_3.tscn")
        
