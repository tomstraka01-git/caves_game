extends Area2D

@export var coin_value: int = 1  
@onready var parent = $".."  
var coin = preload("res://inventory/items/coin_item.tres")
			

func _ready():
   
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("character"): 
		
		
		$AudioStreamPlayer2D.play()
		GameState.inventory.add_item(coin, 1)
		await get_tree().create_timer(0.1).timeout
		parent.queue_free() 
