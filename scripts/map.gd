extends Node2D

@export var first_line_1: String = ""
@export var first_line_2: String = ""

@export var second_line_1: String = ""
@export var second_line_2: String = ""

@export var third_line_1: String = ""
@export var third_line_2: String = ""

@export var fourth_line_1: String = ""
@export var fourth_line_2: String = ""

@export var fifth_line_1: String = ""
@export var fifth_line_2: String = ""

@onready var first = $First
@onready var second = $Second
@onready var third = $Third
@onready var fourth = $Fourth
@onready var fifth = $Fifth
@onready var dialogue = $"../Character/Camera2D/Dialogue"

var triggered_first := false
var triggered_second := false
var triggered_third := false
var triggered_fourth := false
var triggered_fifth := false

func _ready() -> void:
    first.body_entered.connect(_on_first_entered)
    second.body_entered.connect(_on_second_entered)
    third.body_entered.connect(_on_third_entered)
    fourth.body_entered.connect(_on_fourth_entered)
    fifth.body_entered.connect(_on_fifth_entered)

func _on_first_entered(body):
    if body.is_in_group("character") and not triggered_first:
        triggered_first = true
        if first_line_1 != "": dialogue.show_text(first_line_1)
        if first_line_2 != "": dialogue.show_text(first_line_2)

func _on_second_entered(body):
    if body.is_in_group("character") and not triggered_second:
        triggered_second = true
        if second_line_1 != "": dialogue.show_text(second_line_1)
        if second_line_2 != "": dialogue.show_text(second_line_2)

func _on_third_entered(body):
    if body.is_in_group("character") and not triggered_third:
        triggered_third = true
        if third_line_1 != "": dialogue.show_text(third_line_1)
        if third_line_2 != "": dialogue.show_text(third_line_2)

func _on_fourth_entered(body):
    if body.is_in_group("character") and not triggered_fourth:
        triggered_fourth = true
        if fourth_line_1 != "": dialogue.show_text(fourth_line_1)
        if fourth_line_2 != "": dialogue.show_text(fourth_line_2)

func _on_fifth_entered(body):
    if body.is_in_group("character") and not triggered_fifth:
        triggered_fifth = true
        if fifth_line_1 != "": dialogue.show_text(fifth_line_1)
        if fifth_line_2 != "": dialogue.show_text(fifth_line_2)
