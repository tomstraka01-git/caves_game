extends Node2D

@export var max_health := 100
@onready var health_bar := $TextureProgressBar

func _ready():
    health_bar.value = 100
   


 

func change_health(new_health):
    health_bar.value = new_health
