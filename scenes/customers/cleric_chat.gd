extends Control

signal ok_pressed

@onready var ok_button = $Panel/Button

func _ready():
	ok_button.pressed.connect(_on_ok_button_pressed)

func _on_ok_button_pressed():
	queue_free()
