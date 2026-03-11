extends Control

@onready var image: TextureRect = $Image
@onready var text: Label = $InfoText
@onready var click_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var fade: ColorRect = $Fade

@export var fade_time: float = 0.5

var current_image := 0
var transitioning := false

var pages = [
    {
        "image": preload("res://assets/potion2.png"),
        "text": "Use WASD to move"
    },
    {
        "image": preload("res://assets/potion1.png"),
        "text": "Press SPACE to jump"
    },
    {
        "image": preload("res://assets/potion3.png"),
        "text": "Click to attack\n\nPress E to continue"
    }
]


func _ready():
    fade.visible = true
    fade.modulate.a = 0.0
    show_page()


func _input(event):
    if event.is_action_pressed("interact"):
        next_image()


func next_image():
    if transitioning:
        return

    transitioning = true

    # If player presses E on the final page
    if current_image == pages.size() - 1:
        play_click_and_fade("res://scenes/main_menu.tscn")
        return

    await fade_image()



    transitioning = false


func show_page():
    image.texture = pages[current_image]["image"]
    text.text = pages[current_image]["text"]


func fade_image():
    click_sound.pitch_scale = 0.8
    click_sound.play()

    var tween = create_tween()
    tween.tween_property(fade, "modulate:a", 1.0, fade_time)
    await tween.finished
    
    current_image += 1
    show_page()
    
    tween = create_tween()
    tween.tween_property(fade, "modulate:a", 0.0, fade_time)
    await tween.finished


func play_hover():
    click_sound.pitch_scale = 0.8
    click_sound.play()


func play_click_and_fade(scene_path):
    click_sound.pitch_scale = 0.8
    click_sound.play()

    var tween = create_tween()
    tween.tween_property(fade, "modulate:a", 1.0, fade_time)
    await tween.finished

    await get_tree().create_timer(0.2).timeout

    if scene_path != null:
        get_tree().change_scene_to_file(scene_path)
    else:
        get_tree().quit()


func _on_back_pressed() -> void:
    play_click_and_fade("res://scenes/main_menu.tscn")


func _on_back_mouse_entered() -> void:
    play_hover()
