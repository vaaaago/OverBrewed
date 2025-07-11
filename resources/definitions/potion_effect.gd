class_name PotionEffect
extends Resource

@export var name: String
@export var health_restoration: bool
@export var speed_reduction: bool
@export var paralysis: bool
@export var speed_increase: bool
@export var particle_color: Color
@export var has_duration: bool
@export var duration: float = 15.0

func apply_effect(player: Player) -> void:
	if speed_reduction:
		player.max_speed = player.initial_max_speed / 3
	elif speed_increase:
		player.max_speed = player.initial_max_speed * 1.5
	elif paralysis:
		player.max_speed = 0
	elif health_restoration:
		player.remove_effect()
	
	if has_duration:
		player.start_effect_timer(duration)
