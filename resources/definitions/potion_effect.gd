class_name PotionEffect
extends Resource

@export var name: String
@export var health_restoration: bool
@export var speed_reduction: bool
@export var paralysis: bool
@export var speed_increase: bool

func apply_effect(player: Player) -> void:
	if speed_reduction:
		player.max_speed /= 3
	elif speed_increase:
		player.max_speed *= 1.5
	elif paralysis:
		player.max_speed = 0
	elif health_restoration:
		player.remove_effect()
