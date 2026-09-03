# hurt_data.gd
class_name HurtData
extends RefCounted

var hurt_type: Types.HurtType
var knockback_direction: Vector2 = Vector2.ZERO
var knockback_speed: float = 0.0
var z_velocity: float = 0.0
