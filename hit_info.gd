# hit_info.gd
class_name HitInfo
extends RefCounted

var power: float
var damage: float
var attack_direction: Vector2 = Vector2.ZERO
var knockback_speed: float = 0.0
var z_velocity: float = 0.0
