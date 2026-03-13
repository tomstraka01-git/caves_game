extends Control

@onready var image: TextureRect = $Image
@onready var text: Label = $Image/InfoText
@onready var click_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var fade: ColorRect = $Fade
@onready var continue_label: Label = $Image/ContinueLabel

@export var fade_time: float = 0.5

var current_image := 0
var transitioning := false

var pages = [
    {
        "image": preload("res://tutorial/move.png"),
        "text": "Use [A] and [D] to move left or right",
        "offset": Vector2(280, 230)
    },
    {
        "image": preload("res://tutorial/jump.png"),
        "text": "Press SPACE to jump",
        "offset": Vector2(400, 230)
    },
    {
        "image": preload("res://tutorial/press_f_to_attack_tutorial.png"),
        "text": "Press [F] to attack enemies\n",
        "offset": Vector2(300, 280)
    },

    {
        "image": preload("res://tutorial/air_attack_full_finalk_final.png"),
        "text": "Jump then hold [F] for air attack\nwhen you are done charging release the [F]",
        "offset": Vector2(300, 280)
    },
    {
        "image": preload("res://tutorial/press_e_to_interact_tutorial.png"),
        "text": "Press [E] to interact with items or characters,\nenter portals, move dialogue and many more",
        "offset": Vector2(150, 280)
    },
        {
        "image": preload("res://tutorial/tab_inventory_tutorial.png"),
        "text": "Press [TAB] to open inventory,\nselect items with left click, drop them with right and equip or use them with left",
        "offset": Vector2(150, 280)
    },
]

func _ready():
    fade.visible = true
    fade.modulate.a = 0.0
    show_page()

func _unhandled_input(event):
    if event.is_action_pressed("interact"):
        next_image(false)
    if event.is_action_pressed("control_back"):
        next_image(true)

func next_image(is_going_back: bool = false):
    if transitioning:
        return
    if is_going_back and current_image == 0:
        return
    transitioning = true
    if not is_going_back and current_image == pages.size() - 1:
        play_click_and_fade("res://scenes/main_menu.tscn")
        return
    await fade_image(is_going_back)
    transitioning = false

func show_page():
    image.texture = pages[current_image]["image"]
    text.text = pages[current_image]["text"]
    text.position = pages[current_image]["offset"] 
    if current_image == 0:
        continue_label.text = "Press [E] to continue"
    elif current_image == pages.size() - 1:
        continue_label.text = "Press [E] to go to main menu\nor [Q] to go back"
    else:
        continue_label.text = "Press [E] to continue\nor [Q] to go back"

func fade_image(is_back: bool = false):
    click_sound.pitch_scale = 0.8
    click_sound.play()
    var tween = create_tween()
    tween.parallel().tween_property(fade, "modulate:a", 1.0, fade_time)
    tween.parallel().tween_property(image, "modulate:a", 0.0, fade_time)
    await tween.finished
    if is_back:
        current_image -= 1
    else:
        current_image += 1
    show_page()
    image.modulate.a = 0.0
    tween = create_tween()
    tween.parallel().tween_property(fade, "modulate:a", 0.0, fade_time)
    tween.parallel().tween_property(image, "modulate:a", 1.0, fade_time)
    await tween.finished

func play_hover():
    click_sound.pitch_scale = 0.8
    click_sound.play()

func play_click_and_fade(scene_path):
    click_sound.pitch_scale = 0.8
    click_sound.play()
    var tween = create_tween()
    tween.parallel().tween_property(fade, "modulate:a", 1.0, fade_time)
    tween.parallel().tween_property(image, "modulate:a", 0.0, fade_time)
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
