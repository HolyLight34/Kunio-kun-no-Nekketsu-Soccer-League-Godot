extends Area2D
class_name HurtBox
@export var target: CharacterBody2D
signal hit_received(hit_box: HitBox)
func _on_area_entered(area: Area2D) -> void:
	if not area is HitBox:
		return
	hit_received.emit(area as HitBox)
