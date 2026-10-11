
class_name Field
extends Node


## =============================================================================
## Field
##
## 足球场的场地信息入口。
##
## 负责：
## - 保存基础地面类型。
## - 查询特殊地形效果。
## - 提供球门目标点。
## - 提供特殊射门重力参考线。
## - 根据位置和进攻方向查询射门模式。
## - 统一处理左右进攻的坐标镜像。
##
## 不负责：
## - 足球湿度变化。
## - 角色或足球的运动计算。
## - 足球反弹规则。
## - 射门 Z 速度计算。
## =============================================================================


## =============================================================================
## 基础场地数据
## =============================================================================

@export var ground_type: Types.BaseGroundType = Types.BaseGroundType.NORMAL

var _special_ground_regions: Array[SpecialGroundRegion] = []


## =============================================================================
## FC 球场坐标
## =============================================================================

## FC 球场逻辑宽度。
const FIELD_WIDTH: int = 896

## 最后一个整数像素坐标。
const LAST_PIXEL_X: int = FIELD_WIDTH - 1


## =============================================================================
## 向左进攻的原始数据
## =============================================================================

## 左侧球门中心，用于踢球方向计算。
const LEFT_GOAL_CENTER := Vector2(64, 192)

## 左侧球门后方，用于进门后的方向计算。
const LEFT_GOAL_BEHIND := Vector2(-64, 192)

## 特殊射门无重力持续时间计算参考线。
const LEFT_SHOT_GRAVITY_REFERENCE_X: int = 272


## =============================================================================
## 射门模式
## =============================================================================

## FC 根据场区选择的射门模式。
enum ShotMode {
	NORMAL,    ## FC $80：普通球
	DOWNWARD,  ## FC $81：红球，Z 初速度 -8
	UPWARD,    ## FC $82：红球，Z 初速度 +1
}


## =============================================================================
## 生命周期
## =============================================================================

func _ready() -> void:
	_collect_special_ground_regions()


## =============================================================================
## 地形查询
## =============================================================================

## 返回当前球场的基础地面类型。
func get_ground_type() -> Types.BaseGroundType:
	return ground_type


## 返回指定世界逻辑坐标所在的特殊地形效果。
func get_ground_effect_at(
	world_position: Vector2
) -> Types.GroundEffect:
	for region in _special_ground_regions:
		if region.contains_point(world_position):
			return region.effect

	return Types.GroundEffect.NONE


## 收集 Field 直接子节点中的特殊地形区域。
func _collect_special_ground_regions() -> void:
	_special_ground_regions.clear()

	for child in get_children():
		if child is SpecialGroundRegion:
			_special_ground_regions.append(child)


## =============================================================================
## 坐标镜像
## =============================================================================

## 镜像连续逻辑坐标。
##
## 用于球门目标点、物理参考线等。
func mirror_position(
	position: Vector2
) -> Vector2:
	return Vector2(
		FIELD_WIDTH - position.x,
		position.y
	)


## 镜像整数像素索引。
##
## 用于 FC 整数场区判断。
func mirror_pixel_x(pixel_x: int) -> int:
	return LAST_PIXEL_X - pixel_x


## 将足球 X 坐标转换为向左进攻的参考坐标。
##
## attack_direction.x < 0：向左进攻，不需要镜像。
## attack_direction.x > 0：向右进攻，需要镜像。
func get_left_attack_x(
	position_x: float,
	attack_direction: Vector2
) -> int:
	var pixel_x: int = floori(position_x)

	if attack_direction.x < 0.0:
		return pixel_x

	return mirror_pixel_x(pixel_x)


## =============================================================================
## 球门目标点
## =============================================================================

## 获取当前进攻方向对应的球门中心。
func get_goal_center(
	attack_direction: Vector2
) -> Vector2:
	if attack_direction.x < 0.0:
		return LEFT_GOAL_CENTER

	return mirror_position(LEFT_GOAL_CENTER)


## 获取当前进攻方向对应的球门后方目标点。
func get_goal_behind(
	attack_direction: Vector2
) -> Vector2:
	if attack_direction.x < 0.0:
		return LEFT_GOAL_BEHIND

	return mirror_position(LEFT_GOAL_BEHIND)


## =============================================================================
## 特殊射门参考线
## =============================================================================

## 获取特殊射门重力参考线。
##
## 向左进攻：272
## 向右进攻：624
func get_shot_gravity_reference_x(
	attack_direction: Vector2
) -> int:
	if attack_direction.x < 0.0:
		return LEFT_SHOT_GRAVITY_REFERENCE_X

	return FIELD_WIDTH - LEFT_SHOT_GRAVITY_REFERENCE_X


## =============================================================================
## 射门场区
## =============================================================================

## 根据足球位置与进攻方向获取射门模式。
##
## 统一使用向左进攻的场区数据：
##
## X 0～111   ：NORMAL    FC $80
## X 112～303 ：DOWNWARD  FC $81
## X 304～607 ：UPWARD    FC $82
## X 608～895 ：NORMAL    FC $80
##
## 向右进攻时自动镜像 X 坐标。
func get_shot_mode(
	position: Vector2,
	attack_direction: Vector2
) -> ShotMode:
	var x: int = get_left_attack_x(
		position.x,
		attack_direction
	)

	if x < 112:
		return ShotMode.NORMAL

	if x < 304:
		return ShotMode.DOWNWARD

	if x < 608:
		return ShotMode.UPWARD

	return ShotMode.NORMAL
