class_name PotionArea
extends Node2D

@export var duration_time: float = 6.0
@export var initial_radius: float = 120.0

@onready var area_2d: Area2D = $Area2D
@onready var collision_shape: Shape2D = $Area2D/CollisionShape2D.shape
@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D

var effect: PotionEffect

func configure(pos: Vector2, item_id: int) -> void:
	var item: Item = Game.item_register[item_id]
	position = pos
	effect = item.potion_effect
	Debug.log("Area configurada")

func _ready() -> void:
	collision_shape.radius = initial_radius
	cpu_particles_2d.emission_sphere_radius = initial_radius
	area_2d.body_entered.connect(_on_body_entered)
	Debug.log("Area inicializada")
	
	var tween_radius: Tween = get_tree().create_tween()
	var tween_particle_radius: Tween = get_tree().create_tween()
	
	tween_radius.tween_property(collision_shape, "radius", 0, duration_time)
	tween_particle_radius.tween_property(cpu_particles_2d, "emission_sphere_radius", 0, duration_time)
	
	await tween_particle_radius.finished
	#Debug.log("Area destruida")
	self.queue_free()

# Se registran cuerpos en capa 1 (Colision de jugador)
func _on_body_entered(body: Node2D) -> void:
	if body.is_class("CharacterBody2D"):
		Debug.log("Efecto entregado a jugador")
		effect.apply_effect(body)
