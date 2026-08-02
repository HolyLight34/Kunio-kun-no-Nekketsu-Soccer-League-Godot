# TickActionData.gd
class_name TickActionData
extends Resource

@export var anim_name: String = ""
## 🌟 核心配表：每一项代表一个 Tick（3 帧）的【位移 vector】与【动画帧号 frame】
@export var ticks: Array[TickStep] = []

## 🌟 是否允许根据输入方向翻转 X 轴（默认允许，后撤步/特殊技能设为 false）
@export var allow_facing_flip: bool = true
