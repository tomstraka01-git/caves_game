extends Control
@onready var stamina_bar = $TextureProgressBarStamina
@onready var regen_delay = $RegenDelayTimer
var regen_speed = 5.0
var regen_speed_empty = 20.0  
var current_stamina = 100.0
var max_stamina = 100.0
var stamina_tween : Tween
var is_empty := false  

var stamina_potion_active = false

func _ready():
    stamina_bar.max_value = max_stamina
    stamina_bar.value = current_stamina

func _physics_process(delta):
    if stamina_potion_active == true:
        current_stamina = max_stamina
        stamina_bar.value = current_stamina
    
    if regen_delay.is_stopped() and current_stamina < max_stamina:
    
        var speed = regen_speed_empty if is_empty else regen_speed
        current_stamina += speed * delta
        current_stamina = clamp(current_stamina, 0, max_stamina)
        stamina_bar.value = current_stamina

        if current_stamina >= max_stamina:
            is_empty = false

func take_stamina(amount_stamina) -> bool:
    if stamina_potion_active:
        return true
    if is_empty:
        return false
    current_stamina -= amount_stamina
    current_stamina = clamp(current_stamina, 0, max_stamina)
    if stamina_tween:
        stamina_tween.kill()
    stamina_tween = create_tween()
    stamina_tween.tween_property(stamina_bar, "value", current_stamina, 0.2)
    regen_delay.start()
    if current_stamina <= 3:
        is_empty = true
        return false
    return true
