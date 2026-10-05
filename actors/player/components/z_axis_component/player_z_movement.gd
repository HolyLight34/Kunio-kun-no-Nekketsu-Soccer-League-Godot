class_name PlayerZMovement
extends Node


## PlayerZMovement
##
## 角色的 Z 轴运动组件。
##
## 负责维护角色的逻辑 Z 高度与 Z 速度，并按照 FC 的离散逻辑步
## 更新角色的垂直运动。
##
## 当前普通跳跃规则：
## - Z 高度和 Z 速度使用 8.8 定点数保存。
## - 每个逻辑步先执行 Z += VZ。
## - 然后执行 VZ -= 0.5。
## - 当角色下降并到达地面时，将 Z 和 VZ 清零并结束空中状态。
##
## 本组件负责：
## - 保存角色的 Z 高度。
## - 保存角色的 Z 速度。
## - 执行角色普通 Z 轴运动。
## - 判断角色是否处于空中。
## - 在角色落地时发出 landed 信号。
##
## 本组件不负责：
## - XY 水平运动。
## - 决定角色什么时候起跳。
## - 决定不同状态能否起跳。
## - 角色的视觉 Z 偏移。
## - 落地后的状态切换。
##
## 外部状态通过 jump() 发起跳跃，
## 并在每个 FC 逻辑步调用 logic_tick() 更新 Z 轴运动。


## 角色落地时发出。
signal landed()


## FC 普通 Z 轴重力。
##
## 使用 8.8 定点数：
## 0x0080 raw = 0.5。
const GRAVITY_RAW: int = 0x0080


## 当前角色的 Z 高度。
##
## 使用 8.8 定点数保存。
var z_height_raw: int = 0


## 当前角色的 Z 速度。
##
## 使用 8.8 定点数保存。
var z_velocity_raw: int = 0


## 角色当前是否处于空中。
var is_in_air: bool = false


# ==============================================================================
# 公共接口
# ==============================================================================

## 返回当前角色的 Z 高度。
##
## 返回值使用普通浮点单位，而不是 8.8 raw 值。
func get_z_height() -> float:
	return FixedPoint.from_raw(z_height_raw)
func get_z_velocity() -> float:
	return FixedPoint.from_raw(z_velocity_raw)

## 使角色以指定的初始 Z 速度起跳。
##
## initial_velocity 使用普通浮点单位。
## 例如 FC 普通跳跃：
##
##     jump(4.0)
func jump(initial_velocity: float) -> void:
	z_velocity_raw = FixedPoint.to_raw(initial_velocity)
	is_in_air = true


## 执行一个 FC 逻辑步的角色 Z 轴运动。
func logic_tick() -> void:
	if not is_in_air:
		return

	# FC：先使用当前 VZ 更新 Z。
	z_height_raw += z_velocity_raw

	# FC：VZ -= 0.5。
	z_velocity_raw -= GRAVITY_RAW

	# 角色下降并到达地面。
	if z_height_raw <= 0 and z_velocity_raw < 0:
		z_height_raw = 0
		z_velocity_raw = 0
		is_in_air = false
		landed.emit()
