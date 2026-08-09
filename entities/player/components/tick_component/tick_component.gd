class_name TickComponent
extends Node

signal tick_triggered

const FRAMES_PER_TICK: int = 3
var _frame_counter: int = 0

func _physics_process(_delta: float) -> void:
	# 🌟 正确脉冲逻辑：先累加帧，跑满 3 帧时触发信号并归零
	_frame_counter += 1
	if _frame_counter >= FRAMES_PER_TICK:
		_frame_counter = 0
		tick_triggered.emit()

## 🌟 纯粹重置：只清空帧计数，不发出信号（用于请求前摇延迟，精准对齐起点）
func reset_tick() -> void:
	_frame_counter = 0
