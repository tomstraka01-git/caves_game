extends Node2D

var gate_max_value = 100

@onready var gate = $Gate
@onready var gate_bars = $TextureProgressBarGate
@onready var collision_gate = $StaticBody2D/CollisionShapeGateBars

var is_inside = false
var gate_fall_time = 3.0
var gate_moving = false
var gate_open = false


func _ready() -> void:
    gate_bars.visible = true
    gate.visible = true
    collision_gate.disabled = false
    gate_bars.max_value = gate_max_value
    gate_bars.value = gate_max_value


func _input(event):
    
    if !is_inside or gate_moving:
        return
    
    if event.is_action_pressed("interact"):
        if GameState.final_level_unlocked == true:
            up_gate()


func up_gate():
    gate_moving = true
    
    var tween = create_tween()
    tween.tween_property(gate_bars, "value", 0, gate_fall_time)
    await tween.finished

    collision_gate.disabled = true
    gate_open = true
    gate_moving = false


func lower_gate():
    gate_moving = true
    
    var tween = create_tween()
    tween.tween_property(gate_bars, "value", gate_max_value, gate_fall_time)
    await tween.finished

    collision_gate.disabled = false
    gate_open = false
    gate_moving = false


func _on_area_2d_body_entered(body: Node2D) -> void:
    if body.is_in_group("character"):
        is_inside = true


func _on_area_2d_body_exited(body: Node2D) -> void:
    if body.is_in_group("characters"):
        is_inside = false
