extends Area2D

@export var fade_time: float = 2


@onready var anim_sprite = $AnimatedSprite2D
var teleporting := false
var fade: ColorRect
var player_inside: bool = false
var player_ref: Node = null

func _process(delta: float) -> void:
    
    
    if player_inside and Input.is_action_just_pressed("interact"):
        _try_enter_portal()

func _ready():
    
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

func _on_body_exited(body):
    if body.is_in_group("character"):
        player_inside = false
        player_ref = null
        anim_sprite.play("idle")
       

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

func animate_error_label():
    var label = $Label
    label.text = "You need a key to unlock" 
    label.modulate.a = 1.0
    label.visible = true
    
  
    var original_pos = label.position
    var tween = create_tween()
    tween.tween_property(label, "position:x", original_pos.x + 8, 0.05)
    tween.tween_property(label, "position:x", original_pos.x - 8, 0.05)
    tween.tween_property(label, "position:x", original_pos.x + 6, 0.05)
    tween.tween_property(label, "position:x", original_pos.x - 6, 0.05)
    tween.tween_property(label, "position:x", original_pos.x, 0.05)
    await tween.finished
    
   
    await get_tree().create_timer(1.0).timeout
    var fade_tween = create_tween()
    fade_tween.tween_property(label, "modulate:a", 0.8, 0.5)
    await fade_tween.finished
    label.visible = false

func fade_and_change_scene():
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
        
