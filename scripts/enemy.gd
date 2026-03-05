extends CharacterBody2D
@export var SPEED = 100.0
@export var ATTACK_RANGE = 40.0
@export var ATTACK_COOLDOWN = 1.2
@export var DETECT_AREA = 200.0
@export var DAMAGE = 10
@export var HEAVY_DAMAGE = 22
@export var HEAVY_ATTACK_CHANCE = 4
@export var HEALTH = 30
@onready var anim_sprite: AnimatedSprite2D = $Pivot/AnimatedSprite2D
@onready var attack_area: Area2D = $Pivot/Attack_Area



var is_idle_sound_playing = false
var is_death_sound_playing = false

var player: CharacterBody2D = null
var attack_timer = 0.0
enum State { IDLE, PATROL, WALK, ATTACK, HEAVY_WINDUP, HIT, DEAD }
var state = State.IDLE
var attack_triggered = false
var attack_id = 0
var coin_scene = preload("res://scenes/coin.tscn")
var knockback_velocity := Vector2.ZERO
const KNOCKBACK_DECAY = 10.0
var patrol_direction := 1.0
const PATROL_DISTANCE = 80.0
var patrol_origin := Vector2.ZERO
var patrol_flip_cooldown := 0.0
func _ready():
	player = get_tree().get_current_scene().get_node("Character")
	patrol_origin = global_position
	anim_sprite.play("idle")
func spawn_coin():
	var coin = coin_scene.instantiate()
	coin.global_position = global_position
	get_parent().add_child(coin)
func _physics_process(delta: float) -> void:
	if player == null or state == State.DEAD:
		return
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO, KNOCKBACK_DECAY * 300.0 * delta
	)
	if state == State.HIT or state == State.HEAVY_WINDUP \
			or (state == State.ATTACK and attack_triggered):
		velocity.x = knockback_velocity.x
		if not is_on_floor():
			velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
		move_and_slide()
		return
	if attack_timer > 0:
		attack_timer -= delta
	var direction = (player.global_position - global_position).x
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < DETECT_AREA:
		if distance_to_player > ATTACK_RANGE:
			state = State.WALK
		elif attack_timer <= 0:
			if randi() % HEAVY_ATTACK_CHANCE == 0:
				attack_timer = ATTACK_COOLDOWN + 0.5
				state = State.HEAVY_WINDUP
				_heavy_attack_sequence()
			else:
				attack_timer = ATTACK_COOLDOWN
				state = State.ATTACK
		else:
			state = State.IDLE
	else:
		state = State.PATROL
	match state:
		State.WALK:
			if distance_to_player > 2.0:
				velocity.x = SPEED * sign(direction) + knockback_velocity.x
				$Pivot.scale.x = sign(direction)
			else:
				velocity.x = 0
			_play_animation("walk")
			_play_sound("walk")
		State.IDLE:
			velocity.x = knockback_velocity.x
			_play_animation("idle")
		State.PATROL:
			_do_patrol(delta)
		State.ATTACK:
			velocity.x = knockback_velocity.x
			if direction != 0:
				$Pivot.scale.x = sign(direction)
			if not attack_triggered:
				attack_triggered = true
				_attack_player(false)
		State.DEAD:
			velocity.x = 0
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is TileMapLayer:
			var local_pos = collider.to_local(collision.get_position())
			var cell_coords = collider.local_to_map(local_pos)
			var tile_data = collider.get_cell_tile_data(cell_coords)
			if tile_data and tile_data.get_custom_data("deadly") == true:
				die_enemy()
				return
func _do_patrol(delta: float) -> void:
	patrol_flip_cooldown -= delta
	var dist_from_origin = global_position.x - patrol_origin.x
	if dist_from_origin > PATROL_DISTANCE and patrol_flip_cooldown <= 0:
		patrol_direction = -1.0
		patrol_flip_cooldown = 0.5
	elif dist_from_origin < -PATROL_DISTANCE and patrol_flip_cooldown <= 0:
		patrol_direction = 1.0
		patrol_flip_cooldown = 0.5
	velocity.x = SPEED * 0.6 * patrol_direction + knockback_velocity.x
	$Pivot.scale.x = patrol_direction
	_play_animation("walk")
func take_damage_enemy(amount: int, knockback_dir: float = 0.0) -> void:
	if state == State.DEAD:
		return
	HEALTH -= amount
	print("Enemy health:", HEALTH)
	if HEALTH <= 0:
		die_enemy()
		return
	attack_id += 1
	attack_triggered = false
	if knockback_dir != 0.0:
		knockback_velocity.x = knockback_dir * 250.0
		knockback_velocity.y = -80.0
	state = State.HIT
	_play_animation("hit")
func _attack_player(is_heavy: bool) -> void:
	var my_id = attack_id
	_play_animation("attack")
	var hit_delay = 0.5 if is_heavy else 0.3
	await get_tree().create_timer(hit_delay).timeout
	if my_id != attack_id or state == State.DEAD:
		return
	var damage = HEAVY_DAMAGE if is_heavy else DAMAGE
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("character") and body.has_method("take_damage"):
			var knockback_dir = sign(body.global_position.x - global_position.x)
			body.take_damage(damage, knockback_dir)
			print("Enemy ", "HEAVY " if is_heavy else "", "attacks player for ", damage)
func _heavy_attack_sequence() -> void:
	var my_id = attack_id
	attack_triggered = true
	velocity.x = 0
	_play_animation("idle")
	await get_tree().create_timer(0.5).timeout
	if my_id != attack_id or state == State.DEAD:
		state = State.IDLE
		attack_triggered = false
		return
	state = State.ATTACK
	_attack_player(true)
func die_enemy() -> void:
	attack_id += 1
	attack_triggered = false
	state = State.DEAD
	_play_animation("death")
	_play_sound("death")
	await get_tree().create_timer(1.4).timeout
	spawn_coin()
	queue_free()
func _play_animation(anim_name: String) -> void:
	if anim_sprite.animation != anim_name or not anim_sprite.is_playing():
		anim_sprite.play(anim_name)
func _on_animated_sprite_2d_animation_finished():
	match anim_sprite.animation:
		"hit":
			state = State.IDLE
			attack_triggered = false
		"attack":
			attack_triggered = false
			state = State.IDLE

func _play_sound(sound :String):
	if sound == "walk" and not is_idle_sound_playing:
		$Audio/Idle.play()
		is_idle_sound_playing = true
	if sound == "death" and not is_death_sound_playing:
		$Audio/Death.play(2.6)
		is_death_sound_playing = true
		

func _on_idle_finished() -> void:
	is_idle_sound_playing = false


func _on_death_finished() -> void:
	is_death_sound_playing = false
