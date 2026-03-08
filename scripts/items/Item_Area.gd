extends Area2D

 
@onready var parent = $".."  
@export var item : Resource

       
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
        GameState.inventory.add_item(item, 1)
        parent.queue_free()
        var panel = body.get_node("CanvasLayer/Panel")
        if panel:
            panel._refresh()
