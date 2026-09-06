class_name HurtBox
extends Area2D
@export var target: CharacterBody2D
@onready var hurt_shape: CollisionShape2D = $HurtShape
signal hit_received(hit_box: HitBox)
func _on_area_entered(area: Area2D) -> void:
	if area is not HitBox:
		return
	var hit_box := area as HitBox
	if hit_box.hit_info == null:
		return
	hit_received.emit(hit_box)
