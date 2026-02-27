extends CharacterBody2D

@onready var anim_sprite = $Pivot/AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -300.0 

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta


	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY


	var direction = 0
	if Input.is_action_pressed("move_left"):
		direction = -1
		$Pivot.scale.x = -1
	elif Input.is_action_pressed("move_right"):
		direction = 1
		$Pivot.scale.x = 1

	velocity.x = direction * SPEED


	move_and_slide()

	
	var new_anim = ""

	if not is_on_floor():
		if velocity.y < 0:
			new_anim = "jump"  
		else:
			new_anim = "fall"  
	elif direction != 0:
		new_anim = "run"
	else:
		new_anim = "idle"

	
	if anim_sprite.animation != new_anim:
		anim_sprite.play(new_anim)
