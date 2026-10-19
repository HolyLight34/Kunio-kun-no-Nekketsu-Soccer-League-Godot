
@tool
class_name FCCollisionRegionProfile
extends Resource


## 对应 FC 原版 Shape 编号。
@export_range(0, 255, 1)
var shape_id: int = 0


## 区域中心相对于角色原点的位置。
@export var position: Vector2 = Vector2.ZERO:
	set(value):
		if position == value:
			return
		position = value
		emit_changed()


## 区域尺寸。
@export var size: Vector2 = Vector2(20.0, 20.0):
	set(value):
		if size == value:
			return
		size = Vector2(
			maxf(value.x, 1.0),
			maxf(value.y, 1.0)
		)
		emit_changed()
