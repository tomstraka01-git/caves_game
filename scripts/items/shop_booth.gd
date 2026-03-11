extends Area2D

@export var shop_data: ShopData
@export var intro_dialogue: Array[String] = [
    "Welcome, traveler! 
I've got the finest wares around.",
    "Take a look at my stock",
    "Press E to browse, 
or ESC to leave anytime!"
]
@export var return_dialogue: String = "Welcome back! 
See anything you like?"

@onready var shop_ui = $CanvasLayer/ShopPanel
@onready var dialogue_panel = $CanvasLayer/Control/DialoguePanel
@onready var dialogue_label = $DialogueLabel
@onready var dialogue_prompt = $CanvasLayer/Control/DialoguePanel/PromptLabel 

var player_inside: bool = false
var has_visited: bool = false
var in_dialogue: bool = false
var dialogue_index: int = 0
var current_dialogue: Array[String] = []

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    dialogue_panel.hide()
    has_visited = GameState.shop_visited
    dialogue_label.visible = false

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("character"):
        player_inside = true
        dialogue_label.visible = true
        dialogue_label.text = "[ E ] Interact"

func _on_body_exited(body: Node) -> void:
    if body.is_in_group("character"):
        player_inside = false
        shop_ui.close()
        _end_dialogue()
        dialogue_label.visible = false

func _process(_delta: float) -> void:
    if not player_inside:
        return
    if in_dialogue:
        if Input.is_action_just_pressed("interact"):
            _advance_dialogue()
        return
    if Input.is_action_just_pressed("interact"):
        if shop_ui.visible:
            shop_ui.close()
        else:
            _start_interaction()
    if not in_dialogue:
        dialogue_label.text = "[ ESC ] Close Shop" if shop_ui.visible else "[ E ] Interact"
func _start_interaction() -> void:
    if not has_visited:
      
        current_dialogue = intro_dialogue
    else:
      
        current_dialogue = [return_dialogue]

    dialogue_index = 0
    in_dialogue = true
    dialogue_panel.show()
    _show_line(dialogue_index)

func _show_line(index: int) -> void:
    dialogue_label.text = current_dialogue[index]
   
    var is_last = (index >= current_dialogue.size() - 1)
    dialogue_prompt.text = "[ E ] Open Shop" if is_last else "[ E ] Next"
    
func _advance_dialogue() -> void:
    dialogue_index += 1
    if dialogue_index >= current_dialogue.size():
   
        _end_dialogue()
        has_visited = true
        GameState.shop_visited = true
        shop_ui.open(shop_data)
    else:
        _show_line(dialogue_index)

func _end_dialogue() -> void:
    in_dialogue = false
    dialogue_index = 0
    current_dialogue = []
    dialogue_panel.hide()
