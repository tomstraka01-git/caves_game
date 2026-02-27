extends CharacterBody2D

@onready var anim_sprite = $Pivot/AnimatedSprite2D
const SPEED = 300.0
const JUMP_VELOCITY = -450.0


func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		anim_sprite.play("jump")

	var direction = 0
	
	if Input.is_action_pressed("move_left"):
		direction = -1
		$Pivot.scale.x = direction
		
	elif Input.is_action_pressed("move_right"):
		direction = 1
		$Pivot.scale.x = direction

	velocity.x = direction * SPEED

	
	if not is_on_floor():
		if velocity.y < 0:
			anim_sprite.play("jump")
		else:
			anim_sprite.play("idle")
	elif direction != 0:
		anim_sprite.play("walk")
	else:
		anim_sprite.play("idle")
	move_and_slide()
