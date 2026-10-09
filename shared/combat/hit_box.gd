# ==============================================================================
# HitBox
# ==============================================================================
#
# 职责：
#   HitBox 是主动命中检测组件。
#
#   它负责：
#   1. 保存当前行为需要传递的 HitInfo。
#   2. 在启用期间检测进入范围的 HurtBox。
#   3. 排除自身目标。
#   4. 将 HitInfo 传递给命中的 HurtBox。
#   5. 命中窗口关闭时，自动清除当前 HitInfo。
#
#   它不负责：
#   - 解释 HitInfo。
#   - 判断踢球、传球、肘击等具体行为。
#   - 计算伤害、击退、足球轨迹等结果。
#   - 决定受击目标应该进入什么状态。
#
# 使用方式：
#   State 负责构造 HitInfo，并通过 set_hit_info() 写入。
#   AnimationPlayer 负责控制 enabled，从而决定命中窗口。
#
#   State
#       ↓ set_hit_info()
#   HitBox
#       ↓ Animation: enabled = true
#   HurtBox
#       ↓ HitInfo
#   Player / Ball
#
# ==============================================================================

class_name HitBox
extends Area2D


# ==============================================================================
# 配置
# ==============================================================================

## 发出这个 HitBox 的对象。
##
## 当前主要用于避免 HitBox 命中自己的 HurtBox。
@export var source: CharacterBody2D


# ==============================================================================
# 状态
# ==============================================================================

## 当前 HitBox 携带的命中信息。
##
## 由行为 State 在动作开始时写入。
## HitBox 关闭后自动清除。
var _current_hit_info: HitInfo = null


## 当前 HitBox 是否启用。
##
## 该属性主要由 AnimationPlayer 控制：
##
## true:
##   开启 Area2D 的检测。
##
## false:
##   关闭检测，并自动清除本次 HitInfo。
##
## 外部不需要直接操作 monitoring。
var enabled: bool = false:
	set(value):
		enabled = value
		monitoring = value

		if not value:
			_current_hit_info = null


# ==============================================================================
# 公共接口
# ==============================================================================

## 设置当前命中窗口需要携带的 HitInfo。
##
## HitBox 只保存和传递数据，不解释其中的内容。
##
## 通常由 Player State 在动作开始时调用。
func set_hit_info(hit_info: HitInfo) -> void:
	_current_hit_info = hit_info


# ==============================================================================
# 碰撞检测
# ==============================================================================

## Area2D 检测到其他 Area2D 进入时调用。
func _on_area_entered(area: Area2D) -> void:
	if area is not HurtBox:
		return

	if _current_hit_info == null:
		return

	var hurt_box := area as HurtBox

	# 不允许命中 HitBox 自己所属的对象。
	if hurt_box.target == source:
		return

	# HitBox 不解释 HitInfo。
	# 只负责把当前数据交给 HurtBox。
	hurt_box.receive_hit(_current_hit_info)
