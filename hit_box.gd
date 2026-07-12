# hit_box.gd (通用的伤害公告牌，人也用它，球也用它)
extends Area2D
class_name HitBox

var damage: float = 0.0
var knockback_force: float = 0.0
var knockback_direction: Vector2 = Vector2.ZERO
func _ready() -> void:
	if has_node("CollisionShape2D"):
		$CollisionShape2D.debug_color = Color(1.0, 0.0, 0.0, 0.4)
func setup(dmg: float, force: float, dir: Vector2) -> void:
	damage = dmg
	knockback_force = force
	knockback_direction = dir.normalized()
