class_name TickStep
extends Resource

## 本 Tick 的 3D 位移向量 (X: 平面水平, Y: 平面纵深, Z: 轴高度)
@export var move_step: Vector3 = Vector3.ZERO

## 本 Tick 的动画帧号（-1 代表继承/保持上一个 Tick 的帧号）
@export var anim_frame: int = -1
func _init(p_step: Vector3 = Vector3.ZERO, p_frame: int = -1) -> void:
	move_step = p_step
	anim_frame = p_frame
# 🌟 方便调试：在 console 打印时能清晰看到 step 和 frame
func _to_string() -> String:
	return "TickStep(step:%s, frame:%d)" % [move_step, anim_frame]
