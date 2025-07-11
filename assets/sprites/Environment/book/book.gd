# El libro vive en la capa de colision 6
class_name Book
extends Node2D

@onready var libro_ui := $LibroUI
@onready var brillo := $book/AnimationPlayer

@onready var boton_siguiente := $LibroUI/Control/NextPage
@onready var boton_anterior := $LibroUI/Control/PreviousPage
@onready var boton_cerrar := $LibroUI/Control/CloseButton

@onready var paginas_izq := [
	$LibroUI/Control/Control/pagIzq_health,
	$LibroUI/Control/Control/pagIzq_speed,
	$LibroUI/Control/Control/pagIzq_poison,
	$LibroUI/Control/Control/pagIzq_sleep,
]

@onready var paginas_der := [
	$LibroUI/Control/Control2/pagDer_health,
	$LibroUI/Control/Control2/pagDer_speed,
	$LibroUI/Control/Control2/pagDer_poison,
	$LibroUI/Control/Control2/pagDer_sleep,
]

var libro_abierto: bool = false
var pagina_actual: int = 0

func _ready() -> void:
	libro_ui.visible = false
	
	brillo.play("brillar")
	
	boton_siguiente.pressed.connect(_on_boton_siguiente_pressed)
	boton_anterior.pressed.connect(_on_boton_anterior_pressed)
	boton_cerrar.pressed.connect(_on_boton_cerrar_pressed)

func mostrar_libro() -> void:
	libro_abierto = !libro_abierto
	libro_ui.visible = libro_abierto
	if libro_abierto:
		pagina_actual = 0
		_mostrar_pagina()

func ocultar_libro() -> void:
	libro_abierto = false
	libro_ui.visible = false

func _mostrar_pagina() -> void:
	# Oculta todas las páginas
	for i in paginas_izq.size():
		paginas_izq[i].visible = false
		paginas_der[i].visible = false
	
	# Muestra la página actual
	if pagina_actual >= 0 and pagina_actual < paginas_izq.size():
		paginas_izq[pagina_actual].visible = true
		paginas_der[pagina_actual].visible = true

func _on_boton_siguiente_pressed() -> void:
	if pagina_actual < paginas_izq.size() - 1:
		pagina_actual += 1
		_mostrar_pagina()

func _on_boton_anterior_pressed() -> void:
	if pagina_actual > 0:
		pagina_actual -= 1
		_mostrar_pagina()

func _on_boton_cerrar_pressed() -> void:
	libro_abierto = false
	libro_ui.visible = false
