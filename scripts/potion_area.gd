class_name PotionArea
extends Node2D

signal configure_ready
signal finished

@export var duration_time: float = 6.0
@export var initial_radius: float = 120.0
@export var initial_amount: int = 200

@onready var area_2d: Area2D = $Area2D
@onready var collision_shape: Shape2D = $Area2D/CollisionShape2D.shape
@onready var cpu_particles_color: CPUParticles2D = $CPUParticlesColor
@onready var cpu_particles_white: CPUParticles2D = $CPUParticlesWhite

var configured: bool = false
var effect: PotionEffect

func configure(pos: Vector2, item_id: int) -> void:
	var item: Item = Game.item_register[item_id]
	position = pos
	effect = item.potion_effect
	#Debug.log("Area configurada")
	
	configured = true
	configure_ready.emit()

func _ready() -> void:
	collision_shape.radius = initial_radius
	
	cpu_particles_color.emission_sphere_radius = initial_radius
	cpu_particles_color.amount = initial_amount
	cpu_particles_white.emission_sphere_radius = initial_radius
	cpu_particles_white.amount = initial_amount
	
	area_2d.body_entered.connect(_on_body_entered)
	
	if not configured:
		await configure_ready
	
	cpu_particles_color.color = effect.particle_color
	#Debug.log("Area inicializada")
	
	var tween_radius: Tween = get_tree().create_tween()
	var tween_color_particle_radius: Tween = get_tree().create_tween()
	var tween_white_particle_radius: Tween = get_tree().create_tween()
	
	tween_radius.tween_property(collision_shape, "radius", 0, duration_time)
	tween_color_particle_radius.tween_property(cpu_particles_color, "emission_sphere_radius", 0, duration_time)
	tween_white_particle_radius.tween_property(cpu_particles_white, "emission_sphere_radius", 0, duration_time)
	
	await tween_radius.finished
	
	finished.emit()
	self.queue_free()

# Se registran cuerpos en capa 1 (Colision de jugador)
func _on_body_entered(body: Node2D) -> void:
	if body.is_class("CharacterBody2D"):
		Debug.log("Efecto: " + effect.name + " aplicado")
		effect.apply_effect(body)
