extends Area2D

@export var fade_time: float = 2
@export var required_coins: int = 5

@onready var portal = $Sprite2D

var teleporting := false
var fade: ColorRect
var player_inside: bool = false
var player_ref: Node = null

func _process(delta: float) -> void:
    portal.rotate(1 * delta)
    
    if player_inside and Input.is_action_just_pressed("interact"):
        _try_enter_portal()

func _ready():
    $PortalSoundSpin.stream.loop = true
    $PortalSoundSpin.play()
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
   

func _on_body_exited(body):
    if body.is_in_group("character"):
        player_inside = false
        player_ref = null
       

func _try_enter_portal():
    if teleporting or player_ref == null:
        return
    var player_coins = player_ref.coins if "coins" in player_ref else 0
    if player_coins >= required_coins:
        teleporting = true
        await fade_and_change_scene()
    else:
        $NotEnoughCoinsSound.play()
        animate_error_label()

func animate_error_label():
    var label = $Label
    label.text = "Not enough coins! Need " + str(required_coins)
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

    var tween = create_tween()
    tween.tween_property(fade, "modulate:a", 1.0, fade_time)
    await tween.finished
    await get_tree().create_timer(0.3).timeout

    var scene_path = current_scene.scene_file_path
    if scene_path == "res://scenes/level_0.tscn":
        get_tree().change_scene_to_file("res://scenes/level_1.tscn")
    elif scene_path == "res://scenes/level_1.tscn":
        get_tree().change_scene_to_file("res://scenes/level_2.tscn")
