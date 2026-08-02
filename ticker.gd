class_name Ticker
extends Node

## 📢 信号：每 3 帧（1 Tick）触发一次
signal tick_triggered

const FRAMES_PER_TICK: int = 3
var _frame_counter: int = 0

func _physics_process(_delta: float) -> void:
	if _frame_counter == 0:
		tick_triggered.emit()
		
	_frame_counter = (_frame_counter + 1) % FRAMES_PER_TICK

## 🌟 强行对齐：当发生起跳/受击等新事件时，立刻重置时钟相位并触发第一帧
func reset_tick_and_trigger() -> void:
	# ... 原有逻辑
	_frame_counter = 0
