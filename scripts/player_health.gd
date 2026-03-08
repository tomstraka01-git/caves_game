extends Node2D

@export var max_health := 100
@onready var health_bar := $TextureProgressBar

func _ready():
    health_bar.value = 100
    health_bar.max_value = 100
   

func _amulet_health(add_max_new_health, current_health):
    health_bar.max_value += add_max_new_health
    max_health = health_bar.max_value
    health_bar.value = current_health

func change_health(new_health):
    health_bar.value = clamp(new_health, 0, health_bar.max_value)
    
