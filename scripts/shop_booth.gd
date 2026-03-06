extends Area2D

@export var shop_data: ShopData
@onready var shop_ui = $CanvasLayer/ShopPanel

var player_inside: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("character"):
        player_inside = true

func _on_body_exited(body: Node) -> void:
    if body.is_in_group("character"):
        player_inside = false
        shop_ui.close()

func _process(_delta: float) -> void:
    if player_inside and Input.is_action_just_pressed("interact"):
        if shop_ui.visible:
            shop_ui.close()
        else:
            shop_ui.open(shop_data)
