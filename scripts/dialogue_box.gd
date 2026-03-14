extends Control

@onready var label = $Label
var full_text := ""
var typing_speed := 0.05
var is_typing := false
var queue: Array = []
var timer: Timer

func _ready():
    timer = Timer.new()
    timer.one_shot = true
    add_child(timer)
    hide()

func show_text(text):
    queue.append(text)
    if not visible and not is_typing:
        _show_next()

func _show_next():
    if queue.is_empty():
        hide()
        return
    var text = queue.pop_front()
    full_text = text
    label.visible_characters = 0
    label.text = full_text
    show()
    is_typing = true
    type_text()

func type_text() -> void:
    while label.visible_characters < full_text.length():
        label.visible_characters += 1
        timer.start(typing_speed)
        await timer.timeout
    is_typing = false

func _input(event):
    if visible:
        if event.is_action_pressed("interact"):
            if is_typing:
                timer.stop()
                label.visible_characters = full_text.length()
                is_typing = false
            else:
                _show_next()
