# ==============================================================================
# PlayerZMovement.gd
#
# FC《热血足球》角色 2.5D Z轴移动组件
#
# 规则：
#
# - Z / VZ 使用 8.8 定点数
# - 精度 1/256
#
# - 每个角色逻辑步：
#
#       Z += VZ
#       VZ -= gravity
#
# - gravity = 0.5
#             = 128 / 256
#
# - 不乘 Godot delta
#
# 组件只负责：
#
#       高度
#       垂直速度
#       重力
#       最高点检测
#       落地检测
#
# 不负责：
#
#       输入
#       状态切换
#       动画
#       水平移动
#
# ==============================================================================
extends ZMovementBase
class_name PlayerZMovement

# ==============================================================================
# 调试
# ==============================================================================
@export_group("Debug")
@export var debug_observation: bool = false
@export var debug_label: String = "player_z"
@export var debug_print_every_step: bool = false
# ==============================================================================
# FC内部状态
# ==============================================================================
## 高度 raw
##
## 例如：
##
## 1.0 = 256
## 4.0 = 1024
#
## 垂直速度 raw
##
## 例如：
##
## 4.0 = 1024
#
## 上一步速度
## 用于检测最高点
## 是否空中
var _debug_step_count: int = 0
# ==============================================================================
# 生命周期
# ==============================================================================
# ==============================================================================
# 公共接口
# ==============================================================================
## 起跳
##
## FC普通跳跃：
##
## jump(4.0)
##
func jump(initial_velocity: float) -> void:
	apply_vertical_velocity(initial_velocity)

# ==============================================================================
func _process_landing() -> void:
	z_height_raw = 0
	z_velocity_raw = 0
	is_in_air = false
	landed.emit()

func _check_landing() -> bool:
	return z_height_raw < 256 and z_velocity_raw < 0
# ==============================================================================
func _debug_print_step(
	state_name: String,
	z_before_raw: int,
	vz_before_raw: int
) -> void:
	if not debug_observation:
		return
	if (
		not debug_print_every_step
		and state_name == "AIR"
	):
		return
	print(
		"[%s] step=%d %s | Z %.6f -> %.6f raw=%d | VZ %.6f -> %.6f raw=%d"
		% [
			debug_label,
			_debug_step_count,
			state_name,
			_from_raw(z_before_raw),
			_from_raw(z_height_raw),
			z_height_raw,
			_from_raw(vz_before_raw),
			_from_raw(z_velocity_raw),
			z_velocity_raw
		]
	)
