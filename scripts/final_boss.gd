extends CharacterBody2D

@export var SPEED = 40.0
@export var ATTACK_RANGE = 60.0
@export var ATTACK_COOLDOWN = 2.0
@export var DETECT_AREA = 200.0
@export var DAMAGE = 12
@export var HEAVY_DAMAGE = 28
@export var HEAVY_ATTACK_CHANCE = 8
@export var MAX_HEALTH = 300
@export var player_path: NodePath = NodePath("../Character")
@export var health_bar_path: NodePath

@onready var anim_sprite: AnimatedSprite2D = $Pivot/AnimatedSprite2D
@onready var attack_area: Area2D = $Pivot/Attack_Area

var health_bar: TextureProgressBar = null
var camera: Camera2D = null
var player: CharacterBody2D = null
var HEALTH = 300

var attack_timer = 0.0
var attack_triggered = false
var attack_id = 0
var _is_dying = false

var knockback_velocity = Vector2.ZERO
const KNOCKBACK_DECAY = 10.0

var patrol_direction = 1.0
const PATROL_DISTANCE = 100.0
var patrol_origin = Vector2.ZERO
var patrol_flip_cooldown = 0.0

var phase2_active = false
const PHASE2_HP_THRESHOLD = 0.5

var _idle_sound_playing = false
var _death_sound_playing = false

var _shake_strength = 0.0
var _shake_decay = 8.0
var _shake_timer = 0.0
var _cam_base_offset = Vector2.ZERO

var _in_hit_anim := false
var _in_attack_anim := false

enum State { IDLE, PATROL, WALK, ATTACK, HEAVY_WINDUP, HIT, DEAD }
var state = State.IDLE

signal boss_died
signal health_changed(current: int, maximum: int)


func _ready():
    HEALTH = MAX_HEALTH
    patrol_origin = global_position

    if not player_path.is_empty():
        player = get_node(player_path)
    if player == null:
        player = get_tree().get_current_scene().get_node_or_null("Character")

    if player:
        camera = player.get_node_or_null("Camera2D")
        if camera:
            _cam_base_offset = camera.offset

    if not health_bar_path.is_empty():
        var hb = get_node_or_null(health_bar_path)
        if hb is TextureProgressBar:
            health_bar = hb

    if health_bar:
        health_bar.max_value = MAX_HEALTH
        health_bar.value = MAX_HEALTH

    anim_sprite.play("idle")

func _physics_process(delta: float):
    if player == null or _is_dying:
        return

    knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * 300.0 * delta)

    if state == State.HIT:
        velocity.x = knockback_velocity.x
        _apply_gravity(delta)
        move_and_slide()
        return

    if _in_attack_anim:
        velocity.x = knockback_velocity.x
        _apply_gravity(delta)
        move_and_slide()
        return

    if state == State.HEAVY_WINDUP:
        velocity.x = knockback_velocity.x
        _apply_gravity(delta)
        move_and_slide()
        return

    if attack_timer > 0.0:
        attack_timer -= delta

    var dir_x = (player.global_position - global_position).x
    var dist = global_position.distance_to(player.global_position)
    var eff_speed = SPEED * (1.5 if phase2_active else 1.0)
    var eff_range = ATTACK_RANGE * (1.2 if phase2_active else 1.0)

    if dist < DETECT_AREA:
        if dist > eff_range:
            state = State.WALK
        elif attack_timer <= 0.0:
            var roll = randi() % HEAVY_ATTACK_CHANCE
            if roll == 0 or (phase2_active and roll <= 1):
                attack_timer = ATTACK_COOLDOWN + (0.3 if phase2_active else 0.5)
                state = State.HEAVY_WINDUP
                _heavy_attack_sequence()
            else:
                attack_timer = ATTACK_COOLDOWN * (0.7 if phase2_active else 1.0)
                state = State.ATTACK
        else:
            state = State.IDLE
    else:
        state = State.PATROL

    match state:
        State.WALK:
            if dist > 2.0:
                velocity.x = eff_speed * sign(dir_x) + knockback_velocity.x
                if abs(dir_x) > 2.0:
                    $Pivot.scale.x = sign(dir_x)
            else:
                velocity.x = 0.0
            _play_animation("walk")
            _play_sound("walk")
        State.IDLE:
            velocity.x = knockback_velocity.x
            _play_animation("idle")
        State.PATROL:
            _do_patrol(delta)
        State.ATTACK:
            velocity.x = knockback_velocity.x
            if abs(dir_x) > 2.0:
                $Pivot.scale.x = sign(dir_x)
            if not attack_triggered:
                attack_triggered = true
                _in_attack_anim = true
                _attack_player(false)
        State.DEAD:
            velocity.x = 0.0

    _apply_gravity(delta)
    move_and_slide()
    _check_deadly_tiles()

func _process(delta: float):
    _process_camera_shake(delta)

func _apply_gravity(delta: float):
    if not is_on_floor():
        velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta

func _check_deadly_tiles():
    for i in get_slide_collision_count():
        var col = get_slide_collision(i)
        var collider = col.get_collider()
        if collider is TileMapLayer:
            var lp: Vector2 = collider.to_local(col.get_position())
            var cc: Vector2i = collider.local_to_map(lp)
            var td: TileData = collider.get_cell_tile_data(cc)
            if td and td.get_custom_data("deadly") == true:
                die_enemy()
                return

func _do_patrol(delta: float):
    patrol_flip_cooldown -= delta
    var dist_from_origin = global_position.x - patrol_origin.x
    if dist_from_origin > PATROL_DISTANCE and patrol_flip_cooldown <= 0.0:
        patrol_direction = -1.0
        patrol_flip_cooldown = 0.5
    elif dist_from_origin < -PATROL_DISTANCE and patrol_flip_cooldown <= 0.0:
        patrol_direction = 1.0
        patrol_flip_cooldown = 0.5
    velocity.x = SPEED * 0.6 * patrol_direction + knockback_velocity.x
    $Pivot.scale.x = patrol_direction
    _play_animation("walk")

func take_damage_enemy(amount: int, knockback_dir: float = 0.0):
    if _is_dying:
        return

    HEALTH -= amount
    HEALTH = max(HEALTH, 0)
    emit_signal("health_changed", HEALTH, MAX_HEALTH)
    _update_health_bar()

    if not phase2_active and HEALTH <= MAX_HEALTH * PHASE2_HP_THRESHOLD:
        _enter_phase2()

    if HEALTH <= 0:
        die_enemy()
        return

    attack_id += 1
    attack_triggered = false
    _in_attack_anim = false

    if knockback_dir != 0.0:
        knockback_velocity.x = knockback_dir * 280.0
        knockback_velocity.y = -90.0

    state = State.HIT
    _in_hit_anim = true
    anim_sprite.play("hit", 1.0, false)
    _shake_camera(3.0, 0.4)

func _attack_player(is_heavy: bool):
    var my_id = attack_id
    var hit_delay = 0.5 if is_heavy else 0.4
    anim_sprite.play("attack", 1.0, false)

    await get_tree().create_timer(hit_delay).timeout

    if my_id != attack_id or _is_dying:
        attack_triggered = false
        _in_attack_anim = false
        state = State.IDLE
        return

    var damage = HEAVY_DAMAGE if is_heavy else DAMAGE
    for body in attack_area.get_overlapping_bodies():
        if body.is_in_group("character") and body.has_method("take_damage"):
            var kdir = sign(body.global_position.x - global_position.x)
            body.take_damage(damage, kdir)
            _shake_camera(6.0 if is_heavy else 4.0, 0.5 if is_heavy else 0.35)

func _heavy_attack_sequence():
    var my_id = attack_id
    attack_triggered = true
    velocity.x = 0.0
    _play_animation("idle")

    var windup_time = 0.35 if phase2_active else 0.5
    await get_tree().create_timer(windup_time).timeout

    if my_id != attack_id or _is_dying:
        state = State.IDLE
        attack_triggered = false
        return

    _in_attack_anim = true
    state = State.ATTACK
    _attack_player(true)

func _enter_phase2():
    phase2_active = true
    anim_sprite.modulate = Color(1.5, 0.3, 0.3)
    await get_tree().create_timer(0.4).timeout
    anim_sprite.modulate = Color.WHITE
    _shake_camera(8.0, 0.6)

func die_enemy():
    if _is_dying:
        return
    _is_dying = true
    attack_id += 1
    attack_triggered = false
    _in_attack_anim = false
    state = State.DEAD
    velocity = Vector2.ZERO
    anim_sprite.play("death", 1.0, false)
    _play_sound("death")
    _shake_camera(10.0, 0.7)
    emit_signal("boss_died")

    await get_tree().create_timer(1.5).timeout
    _spawn_key()
    queue_free()

func _spawn_key():
    var key_scene = preload("res://scenes/soul_item.tscn")
    var key = key_scene.instantiate()
    key.global_position = global_position
    get_parent().add_child(key)

func _shake_camera(strength: float, duration: float):
    _shake_strength = strength
    _shake_timer = duration

func _process_camera_shake(delta: float):
    if camera == null:
        return
    if _shake_timer > 0.0:
        _shake_timer -= delta
        _shake_strength = move_toward(_shake_strength, 0.0, _shake_strength * delta * _shake_decay)
        var mag = max(_shake_strength, 0.0)
        camera.offset = _cam_base_offset + Vector2(
            randf_range(-mag, mag),
            randf_range(-mag, mag)
        )
    else:
        _shake_strength = 0.0
        camera.offset = _cam_base_offset

func _update_health_bar():
    if health_bar == null:
        return
    health_bar.max_value = MAX_HEALTH
    health_bar.value = HEALTH
    var tween = create_tween()
    tween.tween_property(health_bar, "modulate", Color(1.6, 0.4, 0.4), 0.08)
    tween.tween_property(health_bar, "modulate", Color.WHITE, 0.3)

func _play_animation(anim_name: String):
    if anim_sprite.animation != anim_name or not anim_sprite.is_playing():
        anim_sprite.play(anim_name)

func _on_animated_sprite_2d_animation_finished():
    var finished = anim_sprite.animation
    match finished:
        "hit":
            _in_hit_anim = false
            attack_triggered = false
            state = State.IDLE
            _play_animation("idle")
        "attack":
            _in_attack_anim = false
            attack_triggered = false
            state = State.IDLE
            _play_animation("idle")

func _play_sound(sound: String):
    if sound == "walk" and not _idle_sound_playing:
        $Audio/Idle.play()
        _idle_sound_playing = true
    if sound == "death" and not _death_sound_playing:
        $Audio/Death.play(2.6)
        _death_sound_playing = true

func _on_idle_finished():
    _idle_sound_playing = false

func _on_death_finished():
    _death_sound_playing = false
