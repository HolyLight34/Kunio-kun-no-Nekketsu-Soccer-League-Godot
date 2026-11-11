
class_name BallHorizontalMovement
extends Node

@onready var ball: Ball = $"../.."

## 足球水平运动组件
##
## 负责：
## 1. 足球 XY 权威位置和速度
## 2. 空中 Y 轴速度操控
## 3. LANDING 水平速度衰减
## 4. ROLLING 持续减速
## 5. X/Y 分轴位置积分与同步
##
## 坐标和速度均使用 Q8.8 定点数：
## 1 像素 = 256 raw。


# ==============================================================================
# 类型
# ==============================================================================

## 速度衰减发生的阶段。
enum DecayType {
	ROLLING,
	LANDING,
}


# ==============================================================================
# 常量
# ==============================================================================

## 动作 $05：每个 Logic Tick 的空中操控速度变化。
const AIR_STEERING_STEP_RAW: int = 128

## 动作 $05：空中 Y 轴最大速度 3.5。
const AIR_STEERING_MAX_SPEED_RAW: int = 896

## 低速阶段每个衰减调用减少的速度。
const LOW_SPEED_DECAY_RAW: int = 16


# ==============================================================================
# 衰减系数
# ==============================================================================

## 系数采用 Q8.8 定点数表示。
##
## 1/16 = 16 raw
## 3/32 = 24 raw
## 1/8  = 32 raw
## 3/16 = 48 raw
## 1/4  = 64 raw

const DECAY_COEFFICIENT_1_16_RAW: int = 16
const DECAY_COEFFICIENT_3_32_RAW: int = 24
const DECAY_COEFFICIENT_1_8_RAW: int = 32
const DECAY_COEFFICIENT_3_16_RAW: int = 48
const DECAY_COEFFICIENT_1_4_RAW: int = 64


# ==============================================================================
# 衰减表
# ==============================================================================

## 每行：
## [干球, 湿球]
##
## 行索引：
## 0 = GRASS
## 1 = TYPE_1
## 2 = MUD
## 3 = SAND

const ROLLING_DECAY_TABLE: Array = [
	[24, 48],
	[16, 24],
	[24, 32],
	[24, 48],
]


const LANDING_DECAY_TABLE: Array = [
	[24, 48],
	[16, 24],
	[24, 32],
	[48, 48],
]


# ==============================================================================
# 环境数据
# ==============================================================================

var ground_type: Ball.GroundType
var ball_wetness: Ball.Wetness


## 更新足球当前物理环境。
func update_environment(
	new_ground_type: Ball.GroundType,
	new_ball_wetness: Ball.Wetness
) -> void:
	ground_type = new_ground_type
	ball_wetness = new_ball_wetness


# ==============================================================================
# 权威物理状态
# ==============================================================================

## 足球 XY 权威位置。
## 单位：1/256 像素。
var horizontal_position_raw: Vector2i = Vector2i.ZERO


## 足球 XY 权威速度。
## 表示每个 Logic Tick 应移动多少 raw。
var horizontal_velocity_raw: Vector2i = Vector2i.ZERO


## 是否处于普通地面滚动状态。
## 空中状态由 BallZMovement 管理。
var is_rolling: bool = false


# ==============================================================================
# 位置同步
# ==============================================================================
const PLAYER_CONTROL_Y_OFFSET := 1.0
## 当前需要同步的位置（Q8.8）。
var sync_position_raw: Vector2i = Vector2i.ZERO

## 是否持续同步 X 轴。
## false = 正常速度积分。
var is_syncing_x: bool = false

## 是否持续同步 Y 轴。
## false = 正常速度积分。
var is_syncing_y: bool = false

## 同步指定轴的位置，并设置后续 Logic Tick 的同步规则。
##
## position：整数像素坐标。
## sync_x / sync_y：决定对应轴是否持续同步。
##
## 同步时保留足球原有的子像素部分。
## 不修改水平速度。
func sync_position(
	position: Vector2i,
	sync_x: bool = true,
	sync_y: bool = true
) -> void:
	is_syncing_x = sync_x
	is_syncing_y = sync_y

	if sync_x:
		sync_position_raw.x = (
			position.x * FixedPoint.RAW_ONE
			+ posmod(horizontal_position_raw.x, FixedPoint.RAW_ONE)
		)

	if sync_y:
		sync_position_raw.y = (
			(position.y + 1) * FixedPoint.RAW_ONE
			+ posmod(horizontal_position_raw.y, FixedPoint.RAW_ONE)
		)

	if sync_x:
		horizontal_position_raw.x = sync_position_raw.x

	if sync_y:
		horizontal_position_raw.y = sync_position_raw.y


## 取消所有位置同步，恢复 X/Y 正常积分。
func clear_position_sync() -> void:
	is_syncing_x = false
	is_syncing_y = false


# ==============================================================================
# 位置与速度接口
# ==============================================================================

## 设置水平位置。
func set_horizontal_position(position: Vector2) -> void:
	horizontal_position_raw = FixedPoint.vector_to_raw(position)

func set_horizontal_position_raw(position_raw: Vector2i) -> void:
	horizontal_position_raw = position_raw
## 设置水平整数坐标，保留原有子像素。
func set_horizontal_integer_position(position: Vector2i) -> void:
	var raw_position := horizontal_position_raw

	raw_position.x = (
		position.x * FixedPoint.RAW_ONE
		+ posmod(raw_position.x, FixedPoint.RAW_ONE)
	)

	raw_position.y = (
		position.y * FixedPoint.RAW_ONE
		+ posmod(raw_position.y, FixedPoint.RAW_ONE)
	)

	horizontal_position_raw = raw_position


## 获取水平位置。
func get_horizontal_position() -> Vector2:
	return FixedPoint.vector_from_raw(horizontal_position_raw)
func get_horizontal_position_raw() -> Vector2i:
	return horizontal_position_raw
## 获取水平整数坐标。
func get_horizontal_position_integer() -> Vector2i:
	return FixedPoint.raw_vector_to_integer(horizontal_position_raw)


## 设置水平速度。
func set_horizontal_velocity(velocity: Vector2) -> void:
	horizontal_velocity_raw = FixedPoint.vector_to_raw(velocity)

func set_horizontal_velocity_raw(velocity_raw: Vector2i) -> void:
	horizontal_velocity_raw = velocity_raw
## 获取水平速度。
func get_horizontal_velocity() -> Vector2:
	return FixedPoint.vector_from_raw(horizontal_velocity_raw)


# ==============================================================================
# 空中水平操控
# ==============================================================================

## 根据纵向输入调整足球空中 Y 轴速度。
##
## vertical_input：
## -1 = 向上
##  0 = 无输入
## +1 = 向下
##
## 输入幅度不影响调整量。
## 每个 Logic Tick 固定调整 AIR_STEERING_STEP_RAW。
##
## 本函数只修改速度，不修改位置。
func apply_air_steering(vertical_input: float) -> void:
	if vertical_input == 0.0:
		return

	var steering_direction := int(signf(vertical_input))

	horizontal_velocity_raw.y += (
		steering_direction * AIR_STEERING_STEP_RAW
	)

	horizontal_velocity_raw.y = clampi(
		horizontal_velocity_raw.y,
		-AIR_STEERING_MAX_SPEED_RAW,
		AIR_STEERING_MAX_SPEED_RAW
	)


# ==============================================================================
# LANDING 衰减
# ==============================================================================

## 足球每次触地时调用。
##
## 通常连接：
## BallZMovement.landed
##
## 每次触地都会执行一次。
##
## 这里只修改水平速度，不修改水平位置。
func apply_landing_decay() -> void:
	var decay_coefficient_raw := _get_decay_coefficient_raw(
		DecayType.LANDING
	)

	horizontal_velocity_raw = _apply_velocity_decay_raw(
		horizontal_velocity_raw,
		decay_coefficient_raw
	)


# ==============================================================================
# ROLLING 衰减
# ==============================================================================


## 执行一个 Logic Tick 的滚动衰减。
## 这里只修改速度。
func process_rolling_velocity() -> void:
	var decay_coefficient_raw := _get_decay_coefficient_raw(
		DecayType.ROLLING
	)

	# 原版特殊低速双衰减：
	# 当 X、Y 两轴都处于低速范围时，
	# 先额外执行一次衰减，再执行普通衰减。
	var both_axes_are_low_speed := (
		_is_low_speed_raw(horizontal_velocity_raw.x)
		and
		_is_low_speed_raw(horizontal_velocity_raw.y)
	)

	if both_axes_are_low_speed:
		horizontal_velocity_raw = _apply_velocity_decay_raw(
			horizontal_velocity_raw,
			decay_coefficient_raw
		)

	# 普通衰减。
	horizontal_velocity_raw = _apply_velocity_decay_raw(
		horizontal_velocity_raw,
		decay_coefficient_raw
	)


# ==============================================================================
# Logic Tick
# ==============================================================================

## 开始一个足球 Logic Tick。
##
## 顺序：
## 1. 处理滚动速度衰减。
## 2. 判断滚动是否停止。
## 3. 根据 X/Y 同步设置更新位置。
func logic_tick() -> void:

	# 1. 处理本 Tick 速度。
	if ball.can_roll() and horizontal_velocity_raw != Vector2i.ZERO:
		is_rolling = true
		process_rolling_velocity()

	# 2. 判断滚动是否彻底停止。
	if (
		is_rolling
		and horizontal_velocity_raw == Vector2i.ZERO
	):
		is_rolling = false

	# 3. 更新水平位置。
	_update_position()


## 根据同步设置执行位置更新。
func _update_position() -> void:

	# X 轴。
	if is_syncing_x:
		horizontal_position_raw.x = sync_position_raw.x
	else:
		horizontal_position_raw.x += horizontal_velocity_raw.x

	# Y 轴。
	if is_syncing_y:
		horizontal_position_raw.y = sync_position_raw.y
	else:
		horizontal_position_raw.y += horizontal_velocity_raw.y


# ==============================================================================
# 强制停止
# ==============================================================================

func stop_immediately() -> void:
	horizontal_velocity_raw = Vector2i.ZERO
	is_rolling = false


# ==============================================================================
# 速度衰减计算
# ==============================================================================

## 对 X/Y 两轴分别执行一次速度衰减。
func _apply_velocity_decay_raw(
	velocity_raw: Vector2i,
	decay_coefficient_raw: int
) -> Vector2i:
	return Vector2i(
		_apply_component_decay_raw(
			velocity_raw.x,
			decay_coefficient_raw
		),
		_apply_component_decay_raw(
			velocity_raw.y,
			decay_coefficient_raw
		)
	)


## 对单个速度分量执行一次衰减。
func _apply_component_decay_raw(
	velocity_raw: int,
	decay_coefficient_raw: int
) -> int:

	# 低速阶段：固定减少 LOW_SPEED_DECAY_RAW。
	if _is_low_speed_raw(velocity_raw):
		return move_toward(
			velocity_raw,
			0,
			LOW_SPEED_DECAY_RAW
		)

	# 高速阶段：根据衰减系数计算速度损耗。
	var velocity_loss_raw := _calculate_signed_velocity_loss_raw(
		velocity_raw,
		decay_coefficient_raw
	)

	return velocity_raw - velocity_loss_raw


## 根据衰减系数计算有符号速度损耗。
##
## 使用移位和加法实现分数系数。
##
## 注意：
## 保留原版整数移位计算，不使用浮点数乘法。
func _calculate_signed_velocity_loss_raw(
	velocity_raw: int,
	decay_coefficient_raw: int
) -> int:

	match decay_coefficient_raw:

		# 1/16
		DECAY_COEFFICIENT_1_16_RAW:
			return velocity_raw >> 4

		# 3/32 = 1/16 + 1/32
		DECAY_COEFFICIENT_3_32_RAW:
			return (
				(velocity_raw >> 4)
				+
				(velocity_raw >> 5)
			)

		# 1/8
		DECAY_COEFFICIENT_1_8_RAW:
			return velocity_raw >> 3

		# 3/16 = 1/8 + 1/16
		DECAY_COEFFICIENT_3_16_RAW:
			return (
				(velocity_raw >> 3)
				+
				(velocity_raw >> 4)
			)

		# 1/4
		DECAY_COEFFICIENT_1_4_RAW:
			return velocity_raw >> 2

		_:
			push_error(
				"BallHorizontalMovement: "
				+ "不支持的速度衰减系数：%d raw"
				% decay_coefficient_raw
			)
			return 0


# ==============================================================================
# 低速判断
# ==============================================================================

## FC 原版低速范围：
##
## -256 <= velocity_raw < 256
##
## -1.0 属于低速。
## +1.0 不属于低速。
func _is_low_speed_raw(velocity_raw: int) -> bool:
	return (
		velocity_raw >= -FixedPoint.RAW_ONE
		and velocity_raw < FixedPoint.RAW_ONE
	)


# ==============================================================================
# 衰减参数查询
# ==============================================================================

## 根据地面类型、足球湿润程度和衰减阶段，
## 获取对应的速度衰减系数。
func _get_decay_coefficient_raw(
	decay_type: DecayType
) -> int:

	var wetness_index: int = (
		1 if ball_wetness == Ball.Wetness.HEAVY_WET else 0
	)

	var ground_type_index: int = int(ground_type)

	var decay_table: Array

	match decay_type:
		DecayType.LANDING:
			decay_table = LANDING_DECAY_TABLE

		DecayType.ROLLING:
			decay_table = ROLLING_DECAY_TABLE

		_:
			push_error(
				"BallHorizontalMovement: "
				+ "不支持的速度衰减类型：%d"
				% decay_type
			)
			return 0

	if (
		ground_type_index < 0
		or ground_type_index >= decay_table.size()
	):
		push_error(
			"BallHorizontalMovement: "
			+ "无效的地面类型索引：%d"
			% ground_type_index
		)
		return 0

	return decay_table[ground_type_index][wetness_index]
