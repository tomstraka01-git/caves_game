extends Area2D

@export var coin_value: int = 1  
@onready var parent = $".."  
var coin = preload("res://inventory/items/coin_item.tres")
            
var can_pickup = false
var is_kicked = false



func _ready():
    body_entered.connect(_on_body_entered)

    if is_kicked:
        await get_tree().create_timer(0.5).timeout

    can_pickup = true
    
    for body in get_overlapping_bodies():
        _on_body_entered(body)



func _on_body_entered(body):
    if not can_pickup:
        return
    if body.is_in_group("character"): 
        
        
        $AudioStreamPlayer2D.play()
        GameState.inventory.add_item(coin, 1)
        await get_tree().create_timer(0.1).timeout
        var panel = body.get_node("CanvasLayer/Panel")
        if panel:
            panel._refresh()
        parent.queue_free() 
