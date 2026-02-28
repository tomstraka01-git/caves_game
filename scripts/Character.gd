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

@export var min_damage = 15

@export var crit_damage = 30

@export var max_health := 100

var player_health := max_health
@onready var progress_bar = $Camera2D/Player_Health
@onready var coin_label = $Camera2D/Coin_Label

func take_damage(amount: int):
    is_hit = true
    player_health = clamp(player_health - amount, 0, max_health)
    progress_bar.change_health(player_health)
    anim_sprite.play("hit")
    if player_health <= 0:
        die()
func _ready() -> void:
    
    coin_label.text = "Coins: 0"

func _physics_process(delta: float) -> void:
   
    if not is_on_floor():
        velocity += get_gravity() * delta

  
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
       

  
    if not is_attacking and is_hit == false:
        var anim = ""
        if not is_on_floor():
            anim = "jump"
        elif direction != 0:
            anim = "run"
        else:
            anim = "idle"

        if anim_sprite.animation != anim:
            anim_sprite.play(anim)
    move_and_slide()
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
                damage_enemy -= number /2
                body.take_damage_enemy(damage_enemy)
    
    

func _on_animated_sprite_2d_animation_finished() -> void:
   
    if anim_sprite.animation.begins_with("attack_1") or anim_sprite.animation.begins_with("attack"):
        is_attacking = false
    if anim_sprite.animation.begins_with("hit"):
        is_hit = false
        print("finished hit")
func die():
    await get_tree().create_timer(0.3).timeout 
    get_tree().reload_current_scene()
        
        
func add_score(amount: int):
    coins += amount
    coin_label.text = "Coins: " + str(coins)
    
