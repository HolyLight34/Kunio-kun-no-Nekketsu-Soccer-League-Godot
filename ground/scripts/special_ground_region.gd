@tool
class_name SpecialGroundRegion
extends Node2D


## SpecialGroundRegion
##
## 定义球场中的一块特殊地形区域。
##
## 一个特殊区域可以由多个矩形组合而成。
## 外部可以通过 contains_point() 判断指定世界逻辑坐标
## 是否位于当前区域内。
##
## 本类只负责：
## - 描述当前区域是什么特殊地形。
## - 描述当前区域覆盖哪些位置。
##
## 本类不负责：
## - 足球湿度变化。
## - 角色移动规则。
## - 足球反弹规则。
## - 实体进入特殊区域后的具体行为。


## 当前区域的特殊地形类型。
@export var effect: Field.GroundEffect = Field.GroundEffect.PUDDLE


## 构成当前特殊区域的矩形。
##
## 所有矩形坐标都相对于当前 SpecialGroundRegion。
@export var rects: Array[Rect2] = []


## 判断指定世界逻辑坐标是否位于当前特殊区域。
func contains_point(world_position: Vector2) -> bool:
	var local_position := to_local(world_position)

	for rect in rects:
		if rect.has_point(local_position):
			return true

	return false


## 在编辑器中绘制当前特殊区域，方便配置和检查范围。
func _draw() -> void:
	for rect in rects:
		draw_rect(
			rect,
			Color(0.2, 0.5, 1.0, 0.3),
			true
		)


## 编辑器中持续刷新区域显示。
##
## 当前实现优先保持简单。
## 后续如果有需要，可以改成仅在区域数据变化时重新绘制。
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
