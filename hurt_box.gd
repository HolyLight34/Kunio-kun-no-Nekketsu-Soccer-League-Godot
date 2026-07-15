# hurt_box.gd (通用的受击接收器，人也用它，球也用它)
extends Area2D
class_name HurtBox
@export var victim: CharacterBody2D
# 📢 核心通用信号：只要被锤了，就把这发伤害的完整数据作为信号发出去
signal hit_received(hit_box: HitBox)

func _on_area_entered(area: Area2D) -> void:
	if area is HitBox:
		area.hit_landed.emit()
		hit_received.emit(area)
	pass # Replace with function body.
