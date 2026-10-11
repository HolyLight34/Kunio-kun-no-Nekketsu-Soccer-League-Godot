
class_name BallActionCalculator
extends RefCounted


## =============================================================================
## BallActionCalculator
##
## FC 足球动作参数计算器。
##
## 当前实现：
## - 射门场区判断
## - 射门高度分类
## - XY 射门方向及速度
## - Z 高度及初速度
## - 无重力持续时间
## - 初始 3 逻辑步预推进
##
## 不负责修改足球实体、运动组件或状态机。
## =============================================================================


## 射门初始化时提前计算的逻辑步数。
const INITIAL_ADVANCE_TICKS: int = 3

## 射门的水平速度大小。
const SHOT_HORIZONTAL_SPEED: int = 8
## 射门模式持续时间。
const NORMAL_DURATION: int = 16
const DOWNWARD_DURATION: int = 24

## 向左进攻的射门场区边界。
const SHOT_ZONE_1: int = 112
const SHOT_ZONE_2: int = 304
const SHOT_ZONE_3: int = 608

## 高空射门 Z 初速度。
const DOWNWARD_Z_VELOCITY: int = -8
const UPWARD_Z_VELOCITY: int = 1


var _field_data: BallFieldData


## =============================================================================
## 初始化
## =============================================================================

func setup(field_data: BallFieldData) -> void:
	_field_data = field_data


## =============================================================================
## 射门计算
## =============================================================================

## height_threshold 由当前难度决定。
func calculate_shot(
	ball_position: Vector2,
	ball_height: float,
	data: KickData,
	height_threshold: int
) -> BallShotResult:
	var result := BallShotResult.new()

	if _field_data == null:
		result.is_valid = false
		push_error("BallActionCalculator: 场地数据尚未初始化")
		return result

	if data.direction.x == 0.0:
		result.is_valid = false
		push_warning("BallActionCalculator: 无效的进攻方向")
		return result

	var attack_direction: Vector2 = data.direction

	# ================================================================
	# 1. 射门场区
	# ================================================================

	result.shot_mode = _get_shot_mode(
		ball_position.x,
		attack_direction
	)

	# ================================================================
	# 2. 统一计算 XY 方向和速度
	# ================================================================

	var goal_target: Vector2 = _get_goal_center(
		attack_direction
	)

	result.direction = FCDirectionCalculator.calculate(
		ball_position,
		goal_target
	)

	result.horizontal_velocity = (
		result.direction * SHOT_HORIZONTAL_SPEED
	)

	# ================================================================
	# 3. 根据 Z 整数部分确定高度分类
	# ================================================================

	var z_integer: int = FixedPoint.to_integer(
		ball_height
	)

	result.height_category = _get_height_category(
		z_integer,
		height_threshold
	)

	# ================================================================
	# 4. 计算 Z 高度和初速度
	# ================================================================

	result.initial_z_height = ball_height
	result.z_velocity = 0

	match result.height_category:
		BallShotResult.ShotHeightCategory.BELOW_GROUND:
			# 清除负整数部分。
			result.initial_z_height = (
				ball_height - z_integer
			)

		BallShotResult.ShotHeightCategory.GROUND:
			result.initial_z_height = 8.0

		BallShotResult.ShotHeightCategory.LOW_AIR:
			# 保留当前高度，Z 速度为 0。
			pass

		BallShotResult.ShotHeightCategory.HIGH_AIR:
			result.z_velocity = _get_high_shot_z_velocity(
				result.shot_mode
			)

			result.power = data.endurance + 20

	# ================================================================
	# 5. 无重力持续时间
	# ================================================================

	var total_ticks: int = _calculate_duration(
		ball_position.x,
		attack_direction,
		result.shot_mode
	)

	result.duration_ticks = total_ticks - INITIAL_ADVANCE_TICKS

	if result.duration_ticks < 0:
		result.is_valid = false
		push_warning(
			"BallActionCalculator: 无重力持续时间小于预推进步数"
		)
		return result

	# ================================================================
	# 6. 提前推进 3 个逻辑步
	# ================================================================

	result.initial_position = (
		ball_position
		+ result.horizontal_velocity * INITIAL_ADVANCE_TICKS
	)

	result.initial_z_height += (
		result.z_velocity * INITIAL_ADVANCE_TICKS
	)

	return result


## =============================================================================
## Z 高度分类
## =============================================================================

func _get_height_category(
	z_integer: int,
	height_threshold: int
) -> BallShotResult.ShotHeightCategory:
	if z_integer < 0:
		return BallShotResult.ShotHeightCategory.BELOW_GROUND

	if z_integer == 0:
		return BallShotResult.ShotHeightCategory.GROUND

	if z_integer <= height_threshold:
		return BallShotResult.ShotHeightCategory.LOW_AIR

	return BallShotResult.ShotHeightCategory.HIGH_AIR


## =============================================================================
## 场区判断
## =============================================================================

## 将左右进攻统一转换为向左进攻的场区坐标。
func _get_left_attack_x(
	ball_x: float,
	attack_direction: Vector2
) -> int:
	var x: int = FixedPoint.to_integer(ball_x)

	if attack_direction.x < 0.0:
		return x

	return _field_data.field_width - 1 - x


func _get_shot_mode(
	ball_x: float,
	attack_direction: Vector2
) -> Types.ShotMode:
	var x: int = _get_left_attack_x(
		ball_x,
		attack_direction
	)

	if x < SHOT_ZONE_1:
		return Types.ShotMode.NORMAL

	if x < SHOT_ZONE_2:
		return Types.ShotMode.DOWNWARD

	if x < SHOT_ZONE_3:
		return Types.ShotMode.UPWARD

	return Types.ShotMode.NORMAL


## =============================================================================
## 球门方向
## =============================================================================

func _get_goal_center(
	attack_direction: Vector2
) -> Vector2:
	if attack_direction.x < 0.0:
		return _field_data.left_goal_center

	return _field_data.right_goal_center


## =============================================================================
## Z 初速度
## =============================================================================

func _get_high_shot_z_velocity(
	shot_mode: Types.ShotMode
) -> int:
	match shot_mode:
		Types.ShotMode.DOWNWARD:
			return DOWNWARD_Z_VELOCITY

		Types.ShotMode.UPWARD:
			return UPWARD_Z_VELOCITY

		_:
			return 0


## =============================================================================
## 无重力持续时间
## =============================================================================

func _calculate_duration(
	ball_x: float,
	attack_direction: Vector2,
	shot_mode: Types.ShotMode
) -> int:
	match shot_mode:
		Types.ShotMode.NORMAL:
			return NORMAL_DURATION

		Types.ShotMode.DOWNWARD:
			return DOWNWARD_DURATION

		Types.ShotMode.UPWARD:
			var x: int = FixedPoint.to_integer(ball_x)

			if attack_direction.x > 0.0:
				return int(
					(
						_field_data.right_gravity_reference_x - x
					) / SHOT_HORIZONTAL_SPEED
				)

			return int(
				(
					x - _field_data.left_gravity_reference_x
				) / SHOT_HORIZONTAL_SPEED
			)

	return 0
