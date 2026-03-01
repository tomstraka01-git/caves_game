extends Area2D

@export var hp = 20

@onready var parent = $".."

var player_inside: bool = false
var player_ref: Node = null

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _process(_delta):
    if player_inside and Input.is_action_just_pressed("interact"):
        if player_ref.has_method("take_damage"):
            player_ref.take_damage(-hp)
        await get_tree().create_timer(0.1).timeout
        parent.queue_free()

func _on_body_entered(body):
    if body.is_in_group("character"):
        player_inside = true
        player_ref = body

func _on_body_exited(body):
    if body.is_in_group("character"):
        player_inside = false
        player_ref = null
