extends CharacterBody2D

@onready var anim_sprite = $Pivot/AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -300.0 

var attack_index = 0
var is_attacking = false
var ATTACK_COOLDOWN = 1.0
var attack_timer = 0.0




@export var max_health := 100

var player_health := max_health
@onready var progress_bar = $Camera2D/Player_Health

func take_damage(amount: int):
    player_health = clamp(player_health - amount, 0, max_health)
    progress_bar.change_health(player_health)
    if player_health <= 0:
        die()
func _ready() -> void:
    take_damage(0)

func _physics_process(delta: float) -> void:
   
    if not is_on_floor():
        velocity += get_gravity() * delta

  
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY
        is_attacking = false
   
    attack_timer -= delta

    var direction = 0
    if Input.is_action_pressed("move_left"):
        is_attacking = false
    elif Input.is_action_pressed("move_right"):
        is_attacking = false
    if not is_attacking:
        if Input.is_action_pressed("move_left"):
            direction = -1
            $Pivot.scale.x = -1
            is_attacking = false
        elif Input.is_action_pressed("move_right"):
            direction = 1
            $Pivot.scale.x = 1
            is_attacking = false
            
    velocity.x = direction * SPEED
    if Input.is_action_just_pressed("attack") and attack_timer <= 0:
        attack_timer = ATTACK_COOLDOWN
        player_attack()




    

    
    move_and_slide()

    # Death tiles
    for i in get_slide_collision_count():
        var collision = get_slide_collision(i)
        var collider = collision.get_collider()
        if collider is TileMapLayer:
            var tilemap_layer = collider
            var local_pos = tilemap_layer.to_local(collision.get_position())
            var cell_coords = tilemap_layer.local_to_map(local_pos)
            var tile_data = tilemap_layer.get_cell_tile_data(cell_coords)
            if tile_data and tile_data.get_custom_data("deadly") == true:
                die()

  
    if not is_attacking:
        var anim = ""
        if not is_on_floor():
            anim = "jump"
        elif direction != 0:
            anim = "run"
        else:
            anim = "idle"

        if anim_sprite.animation != anim:
            anim_sprite.play(anim)

func player_attack():
    is_attacking = true
    if attack_index == 0:
        anim_sprite.play("attack_1")
        attack_index = 1
    else:
        anim_sprite.play("attack_2")
        attack_index = 0

func _on_animated_sprite_2d_animation_finished() -> void:
    if anim_sprite.animation.begins_with("attack"):
        is_attacking = false

func die():
    await get_tree().create_timer(0.2).timeout 
    get_tree().reload_current_scene()
        
