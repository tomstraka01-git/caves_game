extends Node2D

@onready var first = $First
@onready var second = $Second
@onready var third = $Third
@onready var fourth = $Fourth
@onready var fifth = $Fifth
@onready var dialogue = $"../Character/Camera2D/Dialogue"

var triggered_first := false
var triggered_second := false
var triggered_third := false

func _ready() -> void:
    first.body_entered.connect(_on_first_entered)
    second.body_entered.connect(_on_second_entered)
    third.body_entered.connect(_on_third_entered)
    fourth.body_entered.connect(_on_fourth_entered)
    fifth.body_entered.connect(_on_fifth_entered)

func _on_first_entered(body):
    if body.is_in_group("character") and not triggered_first:
        triggered_first = true
        dialogue.show_text("Where am I?")
        dialogue.show_text("I need to get out")

func _on_second_entered(body):
    if body.is_in_group("character") and not triggered_second:
        triggered_second = true
        
        dialogue.show_text("I should pick it up")
        dialogue.show_text("Maybe its going to be needed")

func _on_third_entered(body):
    if body.is_in_group("character") and not triggered_third:
        triggered_third = true
        dialogue.show_text("Carefull")
        dialogue.show_text("What is that?")

func _on_fourth_entered(body):
    if body.is_in_group("character") and not triggered_third:
        triggered_third = true
        dialogue.show_text("What do i hear?")
        dialogue.show_text("I should go explore it")
        
func _on_fifth_entered(body):
    if body.is_in_group("character") and not triggered_third:
        triggered_third = true        
        dialogue.show_text("... a portal")
        dialogue.show_text("Where does it lead?")
        
       
