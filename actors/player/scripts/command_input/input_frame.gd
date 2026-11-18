

class_name InputFrame
extends RefCounted


# ============================================================
# 方向位
# ============================================================

enum DirectionBits {
	NONE = 0,
	RIGHT = 1,
	LEFT = 2,
	DOWN = 4,
	UP = 8,
}


# ============================================================
# 输入数据
# ============================================================

## 当前逻辑帧编号。
var logic_tick: int = 0

## 当前持续移动方向。
var input_direction: Vector2 = Vector2.ZERO

## 本次逻辑帧新按下的方向位合并结果。
var direction_bits: int = DirectionBits.NONE

## 当前持续按住的功能按钮。
var held_buttons: Array[Types.InputButtonType] = []

## 本次逻辑帧发生的按下事件。
var pressed_events: Array[Types.InputButtonType] = []

## 本次逻辑帧发生的释放事件。
var released_events: Array[Types.InputButtonType] = []
