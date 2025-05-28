extends Node2D

@onready var anim = $AnimationPlayer
@onready var area = $Area2D


var player_in_area = false
var is_open = false

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	
func _on_body_entered(body):
	if body.is_class("CharacterBody2D"):  # Asegurate de que tu jugador se llame "Player"
		player_in_area = true

func _on_body_exited(body):
	if body.is_class("CharacterBody2D"):
		player_in_area = false
		if is_open:
			anim.play("closeChest")
			is_open = false

func _process(delta):
	if player_in_area and Input.is_action_just_pressed("interact"):  # "interact" = tecla E
		if not is_open:
			anim.play("openChest")
			is_open = true
