extends CharacterBody2D

@export var SPEED = 100.0    
@export var ATTACK_RANGE = 40.0 
@export var ATTACK_COOLDOWN = 1.5 
@export var DETECT_AREA = 100
@export var damage_enemy = 10

@onready var anim_sprite = $AnimatedSprite2D

var player: CharacterBody2D = null
var attack_timer = 0.0


func _ready():
  
    player = get_tree().get_current_scene().get_node("Character")

func _physics_process(delta: float) -> void:
    if player == null:
        return

    var direction = (player.global_position - global_position).x
    var distance_to_player = abs(direction)


    if distance_to_player <= DETECT_AREA:

        if distance_to_player > ATTACK_RANGE:
            velocity.x = SPEED * sign(direction) 
            anim_sprite.flip_h = direction < 0
            _play_animation("walk")
        else:
    
            velocity.x = 0
            anim_sprite.flip_h = direction < 0
            _play_animation("attack")

            attack_timer -= delta
            if attack_timer <= 0:
                attack_timer = ATTACK_COOLDOWN
                _attack_player()
    else:
    
        velocity.x = 0
        _play_animation("idle")

    
    if not is_on_floor():
        velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta

    # Move enemy
    move_and_slide()




func _play_animation(anim_name: String) -> void:
    if anim_sprite.animation != anim_name:
        anim_sprite.play(anim_name)

func _attack_player() -> void:
    
    print("Enemy attacks player!")
    $"../Character".take_damage(damage_enemy)
