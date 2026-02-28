extends CharacterBody2D
@export var SPEED = 100.0
@export var ATTACK_RANGE = 40.0
@export var ATTACK_COOLDOWN = 1.5
@export var DETECT_AREA = 200.0
@export var DAMAGE = 10
@export var HEALTH = 40
@onready var anim_sprite: AnimatedSprite2D = $Pivot/AnimatedSprite2D
@onready var attack_area: Area2D = $Pivot/Attack_Area
var player: CharacterBody2D = null
var attack_timer = 0.0

enum State { IDLE, WALK, ATTACK, HIT, DEAD }
var state = State.IDLE
var attack_triggered = false

func _ready():
    player = get_tree().get_current_scene().get_node("Character")
    anim_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func _physics_process(delta: float) -> void:
    if player == null or state == State.DEAD:
        return
    
    # Don't interrupt hit or attack animations
    if state == State.HIT or (state == State.ATTACK and attack_triggered):
        if not is_on_floor():
            velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
        velocity.x = 0
        move_and_slide()
        return

    if attack_timer > 0:
        attack_timer -= delta

    var direction = (player.global_position - global_position).x
    var distance_to_player = abs(direction)

    if distance_to_player < DETECT_AREA:
        if distance_to_player > ATTACK_RANGE:
            state = State.WALK
        else:
            if attack_timer <= 0:
                state = State.ATTACK
            else:
                state = State.IDLE
    else:
        state = State.IDLE

    match state:
        State.WALK:
            velocity.x = SPEED * sign(direction)
            $Pivot.scale.x = sign(direction)
            _play_animation("walk")

        State.IDLE:
            velocity.x = 0
            _play_animation("idle")

        State.ATTACK:
            velocity.x = 0
            $Pivot.scale.x = sign(direction)
            if not attack_triggered:
                attack_triggered = true
                _attack_player()

        State.DEAD:
            velocity.x = 0

    if not is_on_floor():
        velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
    move_and_slide()

func take_damage_enemy(amount: int) -> void:
    if state == State.DEAD:
        return
    HEALTH -= amount
    print("Enemy health:", HEALTH)
    if HEALTH <= 0:
        die_enemy()
        return
    # Switch to HIT state — physics_process will leave it alone until anim finishes
    state = State.HIT
    _play_animation("hit")

func _attack_player() -> void:
    _play_animation("attack")
    attack_timer = ATTACK_COOLDOWN
    await get_tree().create_timer(0.3).timeout
    if state == State.DEAD:
        return
    for body in attack_area.get_overlapping_bodies():
        if body.is_in_group("character") and body.has_method("take_damage"):
            body.take_damage(DAMAGE)
            print("Enemy attacks player!")

func die_enemy() -> void:
    state = State.DEAD
    _play_animation("death")
    await get_tree().create_timer(1.2).timeout
    queue_free()

func _play_animation(anim_name: String) -> void:
    if anim_sprite.animation != anim_name or not anim_sprite.is_playing():
        anim_sprite.play(anim_name)

func _on_animated_sprite_2d_animation_finished():
    var anim_name = anim_sprite.animation
    if anim_name == "hit":
        print("hit finished")
        state = State.IDLE  # return to normal logic
    if anim_name == "attack":
        print("attack anim finished")
        attack_triggered = false
        state = State.IDLE  # return to normal logic
