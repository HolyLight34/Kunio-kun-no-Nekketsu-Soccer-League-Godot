class_name HitBox
extends Area2D
@export var attacker: CharacterBody2D
var hit_info: HitInfo
signal hit(hurt_box: HurtBox)
func _on_area_entered(area: Area2D) -> void:
	if not area is HurtBox:
		return
	hit.emit(area as HurtBox)
