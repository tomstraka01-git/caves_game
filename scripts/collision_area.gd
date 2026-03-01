extends Area2D

@export var coin_value: int = 1  
@onready var parent = $".."  


func _ready():
   
    self.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body.is_in_group("character"): 
        
        if body.has_method("add_score"):
            body.add_score(coin_value)
            $AudioStreamPlayer2D.play()
        await get_tree().create_timer(0.1).timeout
        parent.queue_free() 
