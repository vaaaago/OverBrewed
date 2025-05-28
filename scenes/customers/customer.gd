extends Node2D

signal despawned

var customer_wait_time: float =  30.0
var waiting := true
var time_passed := 0.0
var is_dialog_open := false
var dialog_instance = null

@onready var wait_bar_sprite: Sprite2D = $WaitBar
@onready var interaction_area = $Area2D
@export var dialog_scene: PackedScene 
var player_in_range := false
var bar_total_frames := 12

func _ready():

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
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

func receive_product():
	waiting = false
	leave_store()

func leave_store():
	despawned.emit(self)
	queue_free()
