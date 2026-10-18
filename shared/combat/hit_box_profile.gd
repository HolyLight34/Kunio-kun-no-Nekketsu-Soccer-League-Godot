@tool
class_name HitBoxProfile
extends Resource

@export var enabled: bool = false:
	set(value):
		if enabled == value:
			return
		enabled = value
		emit_changed()

@export var position: Vector2 = Vector2.ZERO:
	set(value):
		if position == value:
			return
		position = value
		emit_changed()

@export var size: Vector2 = Vector2(20, 20):
	set(value):
		if size == value:
			return
		size = value
		emit_changed()

@export var z_min: int = 0:
	set(value):
		if z_min == value:
			return
		z_min = value
		emit_changed()

@export var z_max: int = 0:
	set(value):
		if z_max == value:
			return
		z_max = value
		emit_changed()
