extends Node
class_name ZMovementBase


# ==============================================================================
# 常量
# ==============================================================================

## FC 8.8 定点精度
const RAW_ONE: int = 256

## 每个 Z 逻辑步的重力
const GRAVITY: float = 0.5


# ==============================================================================
# 信号
# ==============================================================================

## 开始垂直运动
signal launched()

## 发生落地
signal landed()



# ==============================================================================
# Z 物理状态
# ==============================================================================

## 当前 Z 高度，内部使用 1/256 raw
var z_height_raw: int = 0

## 当前 Z 速度，内部使用 1/256 raw
## 正数 = 上升
## 负数 = 下降
var z_velocity_raw: int = 0

## 当前是否处于空中
var is_in_air: bool = false


# ==============================================================================
# 外部接口
# ==============================================================================
func set_z_height(value: float) -> void:
	z_height_raw = _to_raw(value)


func get_z_height() -> float:
	return _from_raw(z_height_raw)


func set_z_velocity(value: float) -> void:
	z_velocity_raw = _to_raw(value)


func get_z_velocity() -> float:
	return _from_raw(z_velocity_raw)


## 给物体一个新的垂直初速度，并进入空中状态。
##
## 例如：
## 角色跳跃：4.0
## 足球起球：8.0
func apply_vertical_velocity(initial_velocity: float) -> void:
	z_velocity_raw = _to_raw(initial_velocity)
	is_in_air = true

	launched.emit()


# ==============================================================================
# Z 逻辑步
# ==============================================================================

## 每个 Z 逻辑步执行一次。
## 不乘 delta。
func process_z_step() -> void:
	if not is_in_air:
		return

	_integrate_z_motion()

	if _check_landing():
		_process_landing()


## 公共 Z 运动规则：
##
## 1. Z += VZ
## 2. VZ -= gravity
func _integrate_z_motion() -> void:
	z_height_raw += z_velocity_raw
	z_velocity_raw -= _to_raw(GRAVITY)


# ==============================================================================
# 子类实现
# ==============================================================================

## 子类决定什么时候算落地。
func _check_landing() -> bool:
	return false


## 子类决定落地后怎么处理。
func _process_landing() -> void:
	pass


# ==============================================================================
# Raw 转换
# ==============================================================================

func _to_raw(value: float) -> int:
	return roundi(value * RAW_ONE)


func _from_raw(value: int) -> float:
	return float(value) / RAW_ONE
