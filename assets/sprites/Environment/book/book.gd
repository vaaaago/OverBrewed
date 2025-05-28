extends Node2D

@onready var open_book := $LibroUI/TextureRect
@onready var interaction_area := $Area2D
@onready var libro_ui := $LibroUI

@onready var brillo := $book/AnimationPlayer

@onready var boton_siguiente := $LibroUI/Control/NextPage
@onready var boton_anterior := $LibroUI/Control/PreviousPage
@onready var boton_cerrar := $LibroUI/Control/CloseButton

@onready var textoIzq := $LibroUI/Control/Control/pagIzq
@onready var textoDer := $LibroUI/Control/Control2/pagDer

var player_in_range := false
var libro_abierto = false
var pagina_actual := 0


var paginas := [
	["[center]Página 1 izquierda", "[center]Página 1 derecha"],
	["[center]Página 2 izquierda", "[center]Página 2 derecha"],
	["[center]Página 3 izquierda", "[center]Página 3 derecha"],
	["[center]Página 4 izquierda", "[center]Página 4 derecha"]
]

func _ready():
	libro_ui.visible = false
	
	brillo.play("brillar")
	
	boton_siguiente.pressed.connect(_on_boton_siguiente_pressed)
	boton_anterior.pressed.connect(_on_boton_anterior_pressed)
	boton_cerrar.pressed.connect(_on_boton_cerrar_pressed)

func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"): 
		libro_abierto = !libro_abierto
		libro_ui.visible = libro_abierto
		if libro_abierto:
			pagina_actual = 0
			_mostrar_pagina()

func _on_body_entered(body):
	if body.is_class("CharacterBody2D"):
		player_in_range = true

func _on_body_exited(body: Node2D):
	if body.is_class("CharacterBody2D"):
		player_in_range = false
		libro_abierto = false
		libro_ui.visible = false
		
		
func _mostrar_pagina():
	if pagina_actual >= 0 and pagina_actual < paginas.size():
		textoIzq.text = paginas[pagina_actual][0]
		textoDer.text = paginas[pagina_actual][1]

func _on_boton_siguiente_pressed():
	if pagina_actual < paginas.size() - 1:
		pagina_actual += 1
		_mostrar_pagina()

func _on_boton_anterior_pressed():
	if pagina_actual > 0:
		pagina_actual -= 1
		_mostrar_pagina()

func _on_boton_cerrar_pressed():
	libro_abierto = false
	libro_ui.visible = false
