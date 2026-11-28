class_name Field
extends Node


## =============================================================================
## Field
##
## 足球场的场地信息入口。
##
## 负责：
## - 通过 TileMapLayer 查询指定位置的地面类型。
## - 处理球场坐标镜像。
## - 为 BallActionCalculator 提供初始化所需的场地数据。
##
## 不负责：
## - 角色或足球的运动计算。
## - 足球湿度、反弹和衰减规则。
## - 射门、传球等足球动作的参数计算。
## =============================================================================


## =============================================================================
## 场地配置
## =============================================================================

## 球场地形图块层（用于按坐标查询 Custom Data）。
@export var terrain_tile_map: TileMapLayer

## TileSet 中自定义数据层的名称（与编辑器里配置的名字保持一致）。
const TERRAIN_DATA_LAYER := "ground_type"


## =============================================================================
## FC 球场常量
## =============================================================================

## 球场逻辑宽度。
const FIELD_WIDTH: int = 896

## 最后一个整数像素坐标。
const LAST_PIXEL_X: int = FIELD_WIDTH - 1


## =============================================================================
## 向左进攻的原始场地数据
## =============================================================================

## 左侧球门中心，用于射门方向计算。
const LEFT_GOAL_CENTER := Vector2(64, 192)

## 左侧球门后方目标点，用于进门后的方向计算。
const LEFT_GOAL_BEHIND := Vector2(-64, 192)

## 特殊射门重力参考线。
const LEFT_SHOT_GRAVITY_REFERENCE_X: int = 272


## =============================================================================
## 地形查询
## =============================================================================

## 返回指定位置的地面类型。
func get_ground_type_at(
	world_position: Vector2
) -> Types.GroundType:
	if terrain_tile_map == null:
		return Types.GroundType.NORMAL

	var cell: Vector2i = terrain_tile_map.local_to_map(
		terrain_tile_map.to_local(world_position)
	)
	var tile_data: TileData = terrain_tile_map.get_cell_tile_data(cell)
	if tile_data == null:
		return Types.GroundType.NORMAL

	return tile_data.get_custom_data(TERRAIN_DATA_LAYER) as Types.GroundType


## =============================================================================
## 坐标镜像
## =============================================================================

## 镜像连续逻辑坐标。
##
## 例如：
## 左球门中心 (64, 192) -> 右球门中心 (832, 192)
func mirror_position(position: Vector2) -> Vector2:
	return Vector2(
		FIELD_WIDTH - position.x,
		position.y
	)


## 镜像整数像素索引。
##
## 整数像素范围为 0～895，因此使用 895 - x。
func mirror_pixel_x(pixel_x: int) -> int:
	return LAST_PIXEL_X - pixel_x


## =============================================================================
## 足球动作场地数据
## =============================================================================

## 创建足球动作计算器所需的场地数据。
##
## 根据向左进攻的原始数据，生成左右两套目标坐标。
## 仅负责准备场地信息，不执行足球动作计算。
##
## 通常由 SoccerMatch 在初始化时调用一次。
func create_ball_field_data() -> BallFieldData:
	var data := BallFieldData.new()

	data.field_width = FIELD_WIDTH

	# 球门中心
	data.left_goal_center = LEFT_GOAL_CENTER
	data.right_goal_center = mirror_position(LEFT_GOAL_CENTER)

	# 球门后方目标点
	data.left_goal_behind = LEFT_GOAL_BEHIND
	data.right_goal_behind = mirror_position(LEFT_GOAL_BEHIND)

	# 特殊射门重力参考线
	data.left_gravity_reference_x = LEFT_SHOT_GRAVITY_REFERENCE_X
	data.right_gravity_reference_x = (
		FIELD_WIDTH - LEFT_SHOT_GRAVITY_REFERENCE_X
	)

	return data
