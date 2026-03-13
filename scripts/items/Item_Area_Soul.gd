extends Area2D

@onready var key_sprite = $"../Sprite2D"
@onready var parent = $".."  
@export var item : Resource

var float_height = 5      
var float_speed = 0.5
var base_y = 0.0
    
var can_pickup = false
var is_kicked = false
    



func _process(delta):
    var t = Time.get_ticks_msec() / 1000.0 
    key_sprite.position.y = base_y + sin(t * float_speed * PI * 2) * float_height

    

func _ready():
    base_y = key_sprite.position.y

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
