extends Area2D
@onready var player = $"../Character"
var entered = false

func _ready() -> void:
    pass 






func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("character"):
        if entered == false:
            if player.has_method("play_boss_fight_enter"):
                player.play_boss_fight_enter()
                entered = true
