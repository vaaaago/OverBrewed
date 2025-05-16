extends Node2D

@onready var open_book := $LibroUI/TextureRect
@onready var interaction_area := $Area2D
@onready var texto := $LibroUI/RichTextLabel
@onready var libro_ui := $LibroUI


var player_in_range := false
var libro_abierto = false

func _ready():
	libro_ui.visible = false
	#texto.text = "[center]Era una noche oscura y tormentosa...\n\nContinúa en la siguiente página."
	
	
	
func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"): # define "abrir_libro" como tecla E en Input Map
		#open_book.visible = not open_book.visible
		libro_abierto = !libro_abierto
		libro_ui.visible = libro_abierto


func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		libro_abierto = false
		libro_ui.visible = false
