# hit_box.gd
class_name HitBox
extends Area2D
@export var source: CharacterBody2D
@onready var hit_shape: CollisionShape2D = $CollisionShape2D
var hit_info: HitInfo = null
signal target_detected(
	hurt_box: HurtBox,
	hit_info: HitInfo
)
func _on_area_entered(area: Area2D) -> void:
	
	if area is not HurtBox:
		return
	if hit_info == null:
		return
	
	var hurt_box := area as HurtBox
	print(hurt_box.target.name,"你好")
	if hurt_box.target == source:
		return
	print(hurt_box.target.name,"你好")
	target_detected.emit(
		hurt_box,
		hit_info
	)
	
