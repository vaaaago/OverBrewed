class_name Customer
extends Node2D

signal despawned
signal received_product

var customer_wait_time: float
var waiting := true
var time_passed := 0.0
var is_dialog_open := false
var dialog_instance = null

@onready var wait_bar_sprite: Sprite2D = $WaitBar
@onready var interaction_area = $PlayerInteractionArea

@export var dialog_scene: PackedScene 
@export var accepted_products: Array[Item]

var player_in_range := false
var bar_total_frames := 12
var current_product: Item = null
var product_received: bool = false

func _ready():
	set_multiplayer_authority(1) #Server tendra la autoridad
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Aca elegimos el producto del cliente de entre los disponibles en su lista
	# Por ahora solo hay uno, cambiar a futuro
	current_product = accepted_products.pick_random()

func _process(delta):
	if not waiting:
		return

	time_passed += delta
	# Calcular el índice del frame según el tiempo restante
	var progress_ratio :float = clamp(time_passed / customer_wait_time, 0.0, 1.0)
	var frame_index := int(progress_ratio * (bar_total_frames - 1))

	wait_bar_sprite.frame = frame_index

	if time_passed >= customer_wait_time:
		leave_store()
		
	if player_in_range and Input.is_action_just_pressed("interact"): # "interact" será la acción para la tecla E
		toggle_dialog()


func _on_body_entered(body: Node2D):
	if body.is_class("CharacterBody2D"):
		player_in_range = true

func _on_body_exited(body: Node2D):
	if body.is_class("CharacterBody2D"):
		player_in_range = false
		close_dialog()

func toggle_dialog():
	if is_dialog_open:
		close_dialog()
	else:
		open_dialog()

func open_dialog():
	dialog_instance = dialog_scene.instantiate()
	dialog_instance.ok_pressed.connect(close_dialog)
	get_tree().current_scene.add_child(dialog_instance)
	is_dialog_open = true

func close_dialog():
	if dialog_instance:
		dialog_instance.queue_free()
		dialog_instance = null
	is_dialog_open = false

@rpc("any_peer", "call_local", "reliable")
func receive_product_request(product_id: int, request_peer_id: int) -> void:
	# A ejecutarse solo en el server, para validar solicitud de entrega
	if not is_multiplayer_authority():
		return
	
	if product_id != null and not product_received:
		if product_id == current_product.ID:
			# Producto es aceptado y es correcto
			#Debug.log("Producto correcto")
			product_received = true
			accept_product.rpc()
			
			var player: Player = Game.get_player(request_peer_id).instance
			player.rpc_id(request_peer_id, "confirm_object_deposited")
		else:
			# Producto es aceptado pero es incorrecto
			#Debug.log("Producto incorrecto")
			product_received = true
			
			# A futuro cambiar esto a otro metodo reject_product()
			# para por ejemplo descontar puntos
			accept_product.rpc()
			
			var player: Player = Game.get_player(request_peer_id).instance
			player.rpc_id(request_peer_id, "confirm_object_deposited")
	else:
		#Debug.log("Producto no aceptado")
		return

@rpc("authority", "call_local", "reliable")
func accept_product() -> void:
	if is_multiplayer_authority():
		# Solo el server debe emitir la señal para incrementar puntaje
		#Debug.log("Emitida señal de producto recibido")
		received_product.emit()
	
	waiting = false
	leave_store()

func leave_store():
	despawned.emit(self)
	queue_free()
