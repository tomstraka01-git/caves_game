extends CharacterBody2D
@onready var anim_sprite = $Pivot/AnimatedSprite2D
const SPEED = 300.0
const JUMP_VELOCITY = -300.0 
var attack_index = 0
var is_attacking = false
var ATTACK_COOLDOWN = 1.0
var attack_timer = 0.0
var coins = 0
var is_hit = false
var is_dead := false

@onready var dialogue = $Camera2D/Dialogue
@export var min_damage = 15
@export var crit_damage = 30
@export var max_health := 100
var player_health := max_health
@export var fade_time: float = 0.5
var transitioning := false
@onready var progress_bar = $UI/Player_Health
@onready var coin_label = $UI/Coin_Label
@onready var fade: ColorRect = $CanvasLayer/Fade
@onready var click_sound = $CanvasLayer/Click
@onready var walk_sound = $Audio/Walk
@onready var death_screen: ColorRect = $CanvasLayer/DeathScreen
@onready var death_label: Label = $CanvasLayer/DeathLabel


func _ready() -> void:
    coin_label.text = "Coins: 0"
    fade.modulate.a = 0.0
    death_screen.modulate.a = 0.0
    death_label.modulate.a = 0.0
    print("death_label visible: ", death_label.visible)
    print("death_label modulate: ", death_label.modulate)
    print("death_label position: ", death_label.global_position)
    print("death_label size: ", death_label.size)
    print("death_label text: ", death_label.text)
    $Audio/bgAudio.stream.loop = true
    $Audio/bgAudio.play()


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

func take_damage(amount: int):
    if is_dead:
        return
    is_hit = true
    player_health = clamp(player_health - amount, 0, max_health)
    progress_bar.change_health(player_health)
    anim_sprite.play("hit")
    if player_health <= 0:
        die()

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity += get_gravity() * delta
    if is_dead:
        velocity.x = 0
        move_and_slide()
        return
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY
        is_attacking = false
    attack_timer -= delta
    var direction = 0
    if Input.is_action_pressed("move_left"):
        direction = -1
        $Pivot.scale.x = -1
    elif Input.is_action_pressed("move_right"):
        direction = 1
        $Pivot.scale.x = 1
    velocity.x = direction * SPEED
    if Input.is_action_just_pressed("attack") and attack_timer <= 0:
        attack_timer = ATTACK_COOLDOWN
        player_attack()
    for i in get_slide_collision_count():
        var collision = get_slide_collision(i)
        var collider = collision.get_collider()
        if collider is TileMapLayer:
            var local_pos = collider.to_local(collision.get_position())
            var cell_coords = collider.local_to_map(local_pos)
            var tile_data = collider.get_cell_tile_data(cell_coords)
            if tile_data and tile_data.get_custom_data("deadly") == true:
                die()
                break
    if is_dead:
        return
    if not is_attacking and not is_hit:
        var anim = ""
        if not is_on_floor():
            anim = "jump"
        elif direction != 0:
            anim = "run"
            _play_sound("walk")
        else:
            anim = "idle"
            walk_sound.stop()
        if anim_sprite.animation != anim:
            anim_sprite.play(anim)
    move_and_slide()

func _play_sound(sound: String):
    if sound == "walk":
        if not walk_sound.playing:
            walk_sound.play()

func player_attack():
    is_attacking = true
    var damage_enemy = min_damage
    anim_sprite.play("attack_1")
    var bodies = $Pivot/AnimatedSprite2D/Attack_Area.get_overlapping_bodies()
    for body in bodies:
        if body.is_in_group("enemies"):
            var number = randi() % 10 
            if number == 0:
                damage_enemy = crit_damage
            else:
                damage_enemy -= number / 2
                body.take_damage_enemy(damage_enemy)

func _on_animated_sprite_2d_animation_finished() -> void:
    if is_dead:
        return
    if anim_sprite.animation.begins_with("attack_1") or anim_sprite.animation.begins_with("attack"):
        is_attacking = false
        anim_sprite.play("idle")
    if anim_sprite.animation.begins_with("hit"):
        is_hit = false
        anim_sprite.play("idle")

func die():
    if is_dead or transitioning:
        return
    transitioning = true
    is_dead = true
    is_attacking = false
    is_hit = false
    velocity = Vector2.ZERO
    walk_sound.stop()
    $Audio/bgAudio.stop()
    $Audio/Die.play()
    anim_sprite.play("death")
    await anim_sprite.animation_finished
    
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(death_screen, "modulate:a", 1.0, 0.8)
    tween.tween_property(death_label, "modulate:a", 1.0, 0.6)
    await tween.finished
    print("tween done - death_label modulate: ", death_label.modulate)
    print("tween done - death_label visible: ", death_label.visible)
    print("tween done - death_screen modulate: ", death_screen.modulate)
    
    await get_tree().create_timer(1.2).timeout
    await play_click_and_fade(get_tree().current_scene.scene_file_path)
func add_score(amount: int):
    coins += amount
    coin_label.text = "Coins: " + str(coins)

func _on_back_pressed() -> void:
    if transitioning:
        return
    transitioning = true
    var scene_path = get_tree().current_scene.scene_file_path
    if "level_" in scene_path:
        await play_click_and_fade("res://scenes/levels.tscn")
    elif scene_path == "res://scenes/levels.tscn":
        await play_click_and_fade("res://scenes/main_menu.tscn")

func _on_back_mouse_entered() -> void:
    click_sound.pitch_scale = 0.8
    click_sound.play()
