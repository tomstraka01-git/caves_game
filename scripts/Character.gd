extends CharacterBody2D
@onready var anim_sprite = $Pivot/AnimatedSprite2D
@onready var air_attack_area: Area2D = $Pivot/AnimatedSprite2D/Air_Attack_Area
const SPEED = 300.0
const JUMP_VELOCITY = -300.0
var is_attacking = false
var ATTACK_COOLDOWN = 0.6
var attack_timer = 0.0
var combo_count = 0
var combo_timer = 0.0
const COMBO_WINDOW = 0.8
const COMBO_DAMAGE_MULT = [1.0, 1.3, 1.8]
const COMBO_ANIMS = ["attack_1", "attack_2", "attack_1"]
var is_air_attacking := false
var air_slam_charging := false
var air_slam_falling := false
const AIR_SLAM_FALL_SPEED = 700.0
const AIR_SLAM_DAMAGE_BASE = 35
const AIR_SLAM_DAMAGE_MAX = 60
var air_slam_charge_time := 0.0
const AIR_SLAM_MAX_CHARGE = 2.0
var was_on_floor := false
var is_sliding := false
var slide_timer := 0.0
const SLIDE_SPEED = 650.0
const SLIDE_DURATION = 0.35
const SLIDE_COOLDOWN = 0.8
var slide_direction := 1.0
var slide_cooldown_timer := 0.0
var knockback_velocity := Vector2.ZERO
const KNOCKBACK_DECAY = 12.0
var coins = 0
var is_hit = false
var is_dead := false
var return_stam = true
var stamina_empty = false

const STAMINA_ATTACK  = 10
const STAMINA_DASH    = 20
const STAMINA_AIR_MIN = 10
const STAMINA_AIR_MAX = 30

@export var min_damage = 15
@export var crit_damage = 30
@export var crit_chance = 10
@export var max_health := 100
var player_health := max_health
@onready var bird_audio = $Audio/Birds
@onready var dialogue = $Camera2D/Dialogue
@export var fade_time: float = 0.5
var transitioning := false
@onready var progress_bar = $UI/Player_Health

@onready var fade: ColorRect = $CanvasLayer/Fade
@onready var click_sound = $CanvasLayer/Click
@onready var walk_sound = $Audio/Walk
@onready var death_screen: ColorRect = $CanvasLayer/DeathScreen
@onready var death_label: Label = $CanvasLayer/DeathLabel
@onready var ui = $UI

func _ready() -> void:

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
	bird_audio.stop()
	anim_sprite.play("idle")

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

func turn_audio_off():
	$Audio/bgAudio.stream.loop = false
	$Audio/bgAudio.stop()
	bird_audio.play()

func turn_audio_on():
	$Audio/bgAudio.stream.loop = true
	$Audio/bgAudio.play()
	bird_audio.stop()

func _play_sound(sound: String):
	if sound == "walk":
		if not walk_sound.playing:
			walk_sound.play()

func take_damage(amount: int, knockback_dir: float = 0.0):
	if is_dead or is_sliding:
		return
	is_hit = true
	is_attacking = false
	is_air_attacking = false
	air_slam_charging = false
	air_slam_falling = false
	air_slam_charge_time = 0.0
	anim_sprite.speed_scale = 1.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		remove_collision_exception_with(enemy)
		enemy.remove_collision_exception_with(self)
	combo_count = 0
	combo_timer = 0.0
	player_health = clamp(player_health - amount, 0, max_health)
	progress_bar.change_health(player_health)
	anim_sprite.play("hit")
	if knockback_dir != 0.0:
		knockback_velocity.x = knockback_dir * 300.0
		knockback_velocity.y = -100.0
	if player_health <= 0:
		die()

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = 0
		move_and_slide()
		return
	attack_timer         -= delta
	slide_cooldown_timer -= delta
	combo_timer          -= delta
	if combo_timer <= 0.0:
		combo_count = 0
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0:
			is_sliding = false
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO, KNOCKBACK_DECAY * 300.0 * delta
	)
	var on_floor_now = is_on_floor()
	if is_air_attacking:
		if air_slam_charging:
			air_slam_charge_time += delta
			velocity.y = 0.0
			velocity.x = knockback_velocity.x
			if air_slam_charge_time >= AIR_SLAM_MAX_CHARGE:
				_release_air_slam()
			elif Input.is_action_just_released("attack"):
				_release_air_slam()
		elif air_slam_falling:
			var charge_ratio = clamp(air_slam_charge_time / AIR_SLAM_MAX_CHARGE, 0.0, 1.0)
			velocity.y = lerp(400.0, AIR_SLAM_FALL_SPEED, charge_ratio)
			velocity.x = knockback_velocity.x
			if on_floor_now and not was_on_floor:
				_on_air_slam_land()
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
	was_on_floor = on_floor_now
	var direction = 0
	if not is_sliding and not is_hit and not is_air_attacking:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			is_attacking = false
		if Input.is_action_pressed("move_left"):
			direction = -1
			$Pivot.scale.x = -1
		elif Input.is_action_pressed("move_right"):
			direction = 1
			$Pivot.scale.x = 1
		if Input.is_action_just_pressed("dash") and slide_cooldown_timer <= 0.0 and is_on_floor():
			return_stam = ui.take_stamina(STAMINA_DASH)
			if return_stam == true:
				_start_slide(direction if direction != 0 else $Pivot.scale.x)
			else:
				_not_enough_stamina()
		if Input.is_action_just_pressed("attack") and attack_timer <= 0 and not is_attacking:

			if not is_on_floor():
				attack_timer = ATTACK_COOLDOWN
				_start_air_slam()
			else:
				if ui.take_stamina(STAMINA_ATTACK):
					attack_timer = ATTACK_COOLDOWN
					player_attack()
				else:
					_not_enough_stamina()
	if not is_air_attacking:
		if is_sliding:
			velocity.x = slide_direction * SLIDE_SPEED
		else:
			velocity.x = direction * SPEED + knockback_velocity.x
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is TileMapLayer:
			var local_pos = collider.to_local(collision.get_position())
			var cell_coords = collider.local_to_map(local_pos)
			var tile_data = collider.get_cell_tile_data(cell_coords)
			if tile_data and tile_data.get_custom_data("deadly") == true:
				take_damage(10)
				break
	if is_dead:
		return
	_update_animation(direction)
	move_and_slide()

func _update_animation(direction: int) -> void:
	if is_attacking or is_hit or is_air_attacking:
		return
	if is_sliding:
		walk_sound.stop()
		_safe_play("slide")
		return
	if not is_on_floor():
		_safe_play("jump")
	elif direction != 0:
		_safe_play("run")
		_play_sound("walk")
	else:
		walk_sound.stop()
		_safe_play("idle")

func _safe_play(anim_name: String) -> void:
	if anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)

func _start_slide(dir: float) -> void:
	is_sliding = true
	slide_direction = sign(dir) if dir != 0 else 1.0
	$Pivot.scale.x = slide_direction
	slide_timer = SLIDE_DURATION
	slide_cooldown_timer = SLIDE_COOLDOWN
	walk_sound.stop()
	anim_sprite.play("slide")

func _start_air_slam() -> void:
	is_air_attacking = true
	air_slam_charging = true
	air_slam_falling = false
	air_slam_charge_time = 0.0
	velocity.y = 0.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		add_collision_exception_with(enemy)
		enemy.add_collision_exception_with(self)
	anim_sprite.play("charging")

func _release_air_slam() -> void:
	air_slam_charging = false
	air_slam_falling = true
	var charge_ratio = clamp(air_slam_charge_time / AIR_SLAM_MAX_CHARGE, 0.0, 1.0)
	anim_sprite.speed_scale = lerp(0.8, 1.6, charge_ratio)
	anim_sprite.play("attack_air_falling")

func _on_air_slam_land() -> void:
	air_slam_falling = false
	anim_sprite.speed_scale = 1.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		remove_collision_exception_with(enemy)
		enemy.remove_collision_exception_with(self)
	var charge_ratio = clamp(air_slam_charge_time / AIR_SLAM_MAX_CHARGE, 0.0, 1.0)
	var slam_cost = int(lerp(float(STAMINA_AIR_MIN), float(STAMINA_AIR_MAX), charge_ratio))
	ui.take_stamina(slam_cost)
	var final_damage = int(lerp(AIR_SLAM_DAMAGE_BASE, AIR_SLAM_DAMAGE_MAX, charge_ratio))
	var bodies = air_attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var knockback_dir = sign(body.global_position.x - global_position.x)
			body.take_damage_enemy(final_damage, knockback_dir)
			print("Air slam hit for ", final_damage, " (charge ", int(charge_ratio * 100), "%)")
	velocity.y = 0.0
	air_slam_charge_time = 0.0
	anim_sprite.play("attack_air")

func player_attack() -> void:
	is_attacking = true
	var current_combo = combo_count
	combo_count = (combo_count + 1) % 3
	combo_timer = COMBO_WINDOW
	anim_sprite.play(COMBO_ANIMS[current_combo])
	var is_crit = (randi() % crit_chance == 0)
	var base_damage: int
	if is_crit:
		base_damage = crit_damage
	else:
		var spread = max(1, (crit_damage - min_damage) / 2)
		base_damage = min_damage + randi() % spread
	var final_damage = int(base_damage * COMBO_DAMAGE_MULT[current_combo])
	var bodies = $Pivot/AnimatedSprite2D/Attack_Area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var knockback_dir = sign(body.global_position.x - global_position.x)
			body.take_damage_enemy(final_damage, knockback_dir)
			print("CRIT! " if is_crit else "Hit! ", "Dealt ", final_damage, " (combo ", current_combo + 1, ")")
	$Audio/Sword_Attack.play()

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_dead:
		return
	match anim_sprite.animation:
		"attack_1", "attack_2":
			is_attacking = false
			anim_sprite.play("idle")
		"attack_air":
			if not air_slam_falling:
				is_air_attacking = false
				air_slam_charging = false
				air_slam_charge_time = 0.0
				anim_sprite.play("idle")
		"attack_air_falling":
			if air_slam_falling:
				anim_sprite.play("attack_air_falling")
		"charging":
			if air_slam_charging:
				anim_sprite.play("charging")
		"hit":
			is_hit = false
			anim_sprite.play("idle")
		"slide":
			is_sliding = false
			anim_sprite.play("idle")
		"death":
			pass

func die() -> void:
	if is_dead or transitioning:
		return
	transitioning = true
	is_dead = true
	is_attacking = false
	is_hit = false
	is_sliding = false
	is_air_attacking = false
	air_slam_charging = false
	air_slam_falling = false
	air_slam_charge_time = 0.0
	anim_sprite.speed_scale = 1.0
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

func _not_enough_stamina():
	stamina_empty = true




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
