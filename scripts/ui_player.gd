extends Control

@onready var stamina_bar = $TextureProgressBarStamina
@onready var regen_delay = $RegenDelayTimer

var regen_speed = 20.0
var current_stamina = 100.0

var stamina_tween : Tween

func _ready():
    stamina_bar.value = current_stamina

func _physics_process(delta):
    if regen_delay.is_stopped() and current_stamina < 100:
        current_stamina += regen_speed * delta
        current_stamina = clamp(current_stamina, 0, 100)
        stamina_bar.value = current_stamina

func take_stamina(amount_stamina):
    current_stamina -= amount_stamina
    current_stamina = clamp(current_stamina, 0, 100)

    if stamina_tween:
        stamina_tween.kill()

    stamina_tween = create_tween()
    stamina_tween.tween_property(stamina_bar, "value", current_stamina, 1.0)

    regen_delay.start()
