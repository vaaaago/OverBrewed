class_name CustomerChat
extends Control

signal ok_pressed

@onready var ok_button: Button = $Panel/Button
@onready var texture_rect: TextureRect = $Panel/TextureRect
@onready var label: Label = $Panel/Label

@export var request_type: CustomerRequest

func _ready() -> void:
	ok_button.pressed.connect(_on_ok_button_pressed)

func configure(request_id: int, customer_id: int) -> void:
	if not Game.customer_request_register_ready:
		await Game.customer_request_register_ready_signal
	
	var request: CustomerRequest = Game.customer_request_register[request_id]
	var customer: CustomerResource = Game.customer_register[customer_id]
	
	texture_rect.texture = customer.portrait_texture
	label.text = request.customer_dialog

func _on_ok_button_pressed() -> void:
	queue_free()
