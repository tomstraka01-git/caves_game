extends Area2D
@export var intro_dialogue: Array[String] = [
    "Welcome, traveler! I've got some things to tell you.",
    "Feel free to chat with me anytime!",
    "Press E to continue or ESC to stop."
]
@export var return_dialogue_have_soul: String = "Thanks for the soul im gonna take it from your inventory"
@export var return_dialogue_no_have_soul: String = "Come back when you have my soul in your inventory"
@onready var interact_label = $"../InteractLabel"
@onready var dialogue_label = $"../DialogueLabel"
@onready var prompt_label = $"../CanvasLayer/PromptLabel"
var player_inside: bool = false
var has_visited: bool = false
var in_dialogue: bool = false
var dialogue_index: int = 0
var current_dialogue: Array[String] = []
func _ready() -> void:
    self.body_entered.connect(_on_body_entered)
    self.body_exited.connect(_on_body_exited)
    has_visited = GameState.npc_visited
    interact_label.visible = false
    dialogue_label.visible = false
    prompt_label.visible = false
func _on_body_entered(body: Node) -> void:
    if body.is_in_group("character"):
        player_inside = true
        interact_label.visible = true
        interact_label.text = "[E] Interact"
func _on_body_exited(body: Node) -> void:
    if body.is_in_group("character"):
        player_inside = false
        _end_dialogue()
        interact_label.visible = false
func _process(_delta: float) -> void:
    if not player_inside:
        return
    if in_dialogue:
        if Input.is_action_just_pressed("interact"):
            _advance_dialogue()
        elif Input.is_action_just_pressed("ui_cancel"):
            _end_dialogue()
        return
    if Input.is_action_just_pressed("interact"):
        _start_interaction()
func _start_interaction() -> void:
    if not has_visited:
        current_dialogue = intro_dialogue.duplicate()
    else:
        current_dialogue = []
        if GameState.inventory.items.any(func(i): return i.resource_path == "res://inventory/items/soul_item.tres"):
            current_dialogue.append(return_dialogue_have_soul)
        else:
            current_dialogue.append(return_dialogue_no_have_soul)
    dialogue_index = 0
    in_dialogue = true
    interact_label.visible = false
    dialogue_label.visible = true
    prompt_label.visible = true
    _show_line(dialogue_index)
func _show_line(index: int) -> void:
    dialogue_label.text = current_dialogue[index]
    var is_last = index >= current_dialogue.size() - 1
    prompt_label.text = "[E] Next" if not is_last else "[ESC] Close"
func _advance_dialogue() -> void:
    dialogue_index += 1
    if dialogue_index >= current_dialogue.size():
        _end_dialogue()
        if not has_visited:
            has_visited = true
            GameState.npc_visited = true
        var soul_index = -1
        for i in GameState.inventory.items.size():
            if GameState.inventory.items[i].resource_path == "res://inventory/items/soul_item.tres":
                soul_index = i
                break
        if soul_index != -1:
            GameState.inventory.remove_item(soul_index, 1)
            _refresh_player_panel()
    else:
        _show_line(dialogue_index)
func _end_dialogue() -> void:
    in_dialogue = false
    dialogue_index = 0
    current_dialogue.clear()
    dialogue_label.visible = false
    prompt_label.visible = false
    if player_inside:
        interact_label.visible = true
func _refresh_player_panel() -> void:
    var players = get_tree().get_nodes_in_group("character")
    if players.size() > 0:
        var panel = players[0].get_node_or_null("CanvasLayer/Panel")
        if panel:
            panel._refresh()
