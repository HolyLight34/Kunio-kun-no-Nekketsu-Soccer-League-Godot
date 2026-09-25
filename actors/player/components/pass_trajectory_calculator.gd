## FC 传球轨迹计算器。
##
## 根据足球当前位置、当前 Z 高度和目标位置，
## 按照 FC 原版传球规则计算足球的初始运动速度。
##
## 本类是无状态的静态算法类，只负责轨迹计算：
## - 不保存足球状态
## - 不修改足球
## - 不处理球权
## - 不切换足球状态
## - 不负责实际位置更新
##
## 对外统一使用正常逻辑单位：
## - Vector2：水平位置
## - float：Z 高度
## - Vector3：最终初始速度
##
## FC 内部使用的整数坐标、1/256 定点数、方向量化和 ROM 表
## 均隐藏在本类内部。查
class_name PassTrajectoryCalculator
extends RefCounted


# ==============================================================================
# 传球速度参数
# ==============================================================================

## 普通传球水平速度表。
##
## ROM $A4C6 中保存的是 Q8.8 速度。
##
## 最终水平速度：
##
##     direction_raw * speed_raw >> 8
##
## 得到 Q8.8 velocity。
const PASS_SPEED_RAW: Array[int] = [
	256,   # 1.0
	512,   # 2.0
	512,   # 2.0
	768,   # 3.0
	1024,  # 4.0
	1280,  # 5.0
	1536,  # 6.0
	1536,  # 6.0
]


## 近距离贴地传球使用的特殊速度。
##
## $0A00 = 2560 raw = 10.0
const FLAT_PASS_SPEED_RAW: int = 2560


# ==============================================================================
# Z 轴参数
# ==============================================================================

## 空中传球最大初始 Z 速度。
##
## $1000 = 4096 raw = 16.0
const MAX_PASS_Z_VELOCITY_RAW: int = 4096


## 每增加一个预计飞行逻辑步，
## 初始 Z 速度增加：
##
## 64 raw = 0.25
const PASS_INITIAL_VZ_PER_FLIGHT_STEP_RAW: int = 64


# ==============================================================================
# FC 方向量化 ROM 表
# ==============================================================================

## ratio bucket → direction index
##
## FC 不使用 Vector2.normalized() 计算传球方向。
## 而是根据两个坐标分量的比例查 ROM 表，
## 得到量化后的 Q8.8 方向分量。
const RATIO_TO_DIRECTION_INDEX: Array[int] = [
	0, 1, 2, 4, 5, 6, 8, 9,
	10, 11, 12, 13, 14, 16, 17, 18,
	19, 20, 21, 22, 23, 24, 25, 26,
	27, 28, 28, 29, 30, 31, 31, 32,
]


## FC 量化方向的小轴 Q8.8 分量。
const DIRECTION_SMALL_RAW: Array[int] = [
	0, 7, 15, 20, 25, 33, 38, 48,
	51, 56, 64, 69, 76, 81, 87, 94,
	99, 107, 110, 115, 122, 128, 133, 138,
	140, 148, 153, 158, 163, 166, 174, 176,
	179,
]


## FC 量化方向的大轴 Q8.8 分量。
const DIRECTION_LARGE_RAW: Array[int] = [
	255, 255, 255, 254, 254, 253, 253, 251,
	250, 249, 248, 246, 245, 243, 240, 238,
	235, 232, 230, 227, 225, 222, 220, 215,
	212, 207, 204, 202, 197, 194, 189, 184,
	179,
]


# ==============================================================================
# 对外接口
# ==============================================================================

## 计算 FC 传球的初始速度。
##
## 参数：
## - ball_position：足球当前水平逻辑位置。
## - ball_z_height：足球当前逻辑 Z 高度。
## - target_position：传球目标的水平逻辑位置。
##
## 返回：
##     Vector3(VX, VY, VZ)
##
## 调用方不需要知道内部使用的：
## - 1/256 定点数
## - 整数坐标
## - ROM 方向表
## - 距离档位
## - Q8.8 乘法
static func calculate(
	ball_position: Vector2,
	ball_z_height: float,
	target_position: Vector2
) -> Vector3:
	# FC 传球先分别取得足球和目标的整数坐标，
	# 然后再计算两者之间的坐标差。
	#
	# 不能先计算浮点坐标差，再对结果取整。
	var ball_position_integer := FixedPoint.vector_to_integer(
		ball_position
	)
	var ball_z_integer := FixedPoint.to_integer(
		ball_z_height
	)

	var target_position_integer := FixedPoint.vector_to_integer(
		target_position
	)

	var position_delta := (
		target_position_integer
		- ball_position_integer
	)

	# FC 距离档位：
	#
	# q =
	# floor(abs(dx) / 16)
	# +
	# floor(abs(dy) / 16)
	var distance_q := (
		(absi(position_delta.x) >> 4)
		+
		(absi(position_delta.y) >> 4)
	)

	# 近距离且足球位于地面高度：
	# 使用特殊贴地传球。
	if (
		distance_q <= 5 and ball_z_integer == 0
	):
		return _calculate_flat_pass_velocity(
			position_delta
			)

# 其他情况：
# 使用抛物线传球。
	return _calculate_air_pass_velocity(
		position_delta,
		distance_q,
		ball_z_integer
		)


# ==============================================================================
# 贴地传球
# ==============================================================================

## 计算近距离贴地传球的初始速度。
static func _calculate_flat_pass_velocity(
	position_delta: Vector2i
) -> Vector3:
	var direction_raw := _calculate_direction_raw(
		position_delta
	)

	var velocity_raw := Vector3i(
		_signed_q8_multiply(
			direction_raw.x,
			FLAT_PASS_SPEED_RAW
		),
		_signed_q8_multiply(
			direction_raw.y,
			FLAT_PASS_SPEED_RAW
		),
		0
	)

	return _raw_velocity_to_vector3(
		velocity_raw
	)


# ==============================================================================
# 抛物线传球
# ==============================================================================

## 计算抛物线传球的初始速度。
static func _calculate_air_pass_velocity(
	position_delta: Vector2i,
	distance_q: int,
	ball_z_integer: int
) -> Vector3:
	# ROM 使用的距离索引：
	#
	# min(q, 14) & $0E
	#
	# 最终只会得到偶数：
	# 0, 2, 4, 6, 8, 10, 12, 14
	var distance_index := (
		mini(distance_q, 14)
		& 0x0E
	)

	# ROM 索引是：
	# 0,2,4,6...
	#
	# Godot Array 索引是：
	# 0,1,2,3...
	var pass_speed_raw := PASS_SPEED_RAW[
		distance_index >> 1
	]

	# 根据目标坐标差生成 FC 量化方向。
	var direction_raw := _calculate_direction_raw(
		position_delta
	)

	# Q8.8 direction × Q8.8 speed
	# 得到真正的水平 Q8.8 velocity。
	var horizontal_velocity_raw := Vector2i(
		_signed_q8_multiply(
			direction_raw.x,
			pass_speed_raw
		),
		_signed_q8_multiply(
			direction_raw.y,
			pass_speed_raw
		)
	)

	# --------------------------------------------------------------------------
	# 计算水平预计飞行时间
	# --------------------------------------------------------------------------

	# FC 根据实际生成的 VX / VY，
	# 选择绝对速度最大的轴作为主轴。
	#
	# 距离和速度必须来自同一个轴。
	var dominant_distance: int
	var dominant_speed_raw: int

	if (
		absi(horizontal_velocity_raw.x)
		>=
		absi(horizontal_velocity_raw.y)
	):
		dominant_distance = absi(
			position_delta.x
		)
		dominant_speed_raw = absi(
			horizontal_velocity_raw.x
		)
	else:
		dominant_distance = absi(
			position_delta.y
		)
		dominant_speed_raw = absi(
			horizontal_velocity_raw.y
		)

	# 正常抛物线传球不应该出现主轴速度为 0。
	#
	# 如果触发，说明方向、速度或尚未逆向出的特殊情况存在问题。
	assert(
		dominant_speed_raw > 0,
		"Pass dominant speed must be greater than zero."
	)

	# dominant_distance：
	#     整数像素
	#
	# dominant_speed_raw：
	#     1/256 像素 / logic tick
	#
	# 所以：
	#
	# estimated_flight_steps =
	# floor(
	#     dominant_distance * 256
	#     /
	#     dominant_speed_raw
	# )
	var estimated_flight_steps := (
		dominant_distance
		* FixedPoint.RAW_ONE
	) / dominant_speed_raw

	# --------------------------------------------------------------------------
	# 计算初始 Z 速度
	# --------------------------------------------------------------------------

	# 每增加一个预计飞行 Tick：
	# VZ += 64 raw
	#
	# 最大：
	# VZ = 4096 raw = 16.0
	var z_velocity_raw := mini(
		estimated_flight_steps
		* PASS_INITIAL_VZ_PER_FLIGHT_STEP_RAW,
		MAX_PASS_Z_VELOCITY_RAW
	)

	# 当前足球高度修正。
	#
	# ball_z_integer =
	#     current_ball_z_raw >> 8
	#
	# VZ_raw -=
	#     floor(ball_z_integer / 16) * 256
	#
	# 足球当前越高，新生成的向上速度越低。
	

	z_velocity_raw -= (
		(ball_z_integer >> 4)
		* FixedPoint.RAW_ONE
	)

	# 合并 VX / VY / VZ。
	var velocity_raw := Vector3i(
		horizontal_velocity_raw.x,
		horizontal_velocity_raw.y,
		z_velocity_raw
	)

	return _raw_velocity_to_vector3(
		velocity_raw
	)


# ==============================================================================
# FC 方向量化
# ==============================================================================

## 根据整数坐标差计算 FC 的 Q8.8 方向向量。
##
## FC 不使用 Vector2.normalized()。
##
## 普通流程：
##
##     坐标比例
##         ↓
##     整数除法
##         ↓
##     ratio bucket
##         ↓
##     ROM 查表
##         ↓
##     Q8.8 方向分量
static func _calculate_direction_raw(
	position_delta: Vector2i
) -> Vector2i:
	var abs_x := absi(position_delta.x)
	var abs_y := absi(position_delta.y)

	# --------------------------------------------------------------------------
	# 特例：没有方向
	# --------------------------------------------------------------------------

	if abs_x == 0 and abs_y == 0:
		return Vector2i.ZERO

	# --------------------------------------------------------------------------
	# 特例：纯 Y 轴
	#
	# FC 使用：
	# (0, ±256)
	#
	# 这里不能使用 ROM 表中的 255。
	# --------------------------------------------------------------------------

	if abs_x == 0:
		return Vector2i(
			0,
			FixedPoint.RAW_ONE
				if position_delta.y > 0
				else -FixedPoint.RAW_ONE
		)

	# --------------------------------------------------------------------------
	# 特例：纯 X 轴
	#
	# FC 使用：
	# (±256, 0)
	# --------------------------------------------------------------------------

	if abs_y == 0:
		return Vector2i(
			FixedPoint.RAW_ONE
				if position_delta.x > 0
				else -FixedPoint.RAW_ONE,
			0
		)

	# --------------------------------------------------------------------------
	# 特例：精确 45°
	#
	# FC 使用：
	# (±179, ±179)
	#
	# 而不是现代 normalized() 得到的约 181。
	# --------------------------------------------------------------------------

	if abs_x == abs_y:
		return Vector2i(
			179
				if position_delta.x > 0
				else -179,
			179
				if position_delta.y > 0
				else -179
		)

	# --------------------------------------------------------------------------
	# 普通方向量化
	# --------------------------------------------------------------------------

	var minor_delta := mini(
		abs_x,
		abs_y
	)

	var major_delta := maxi(
		abs_x,
		abs_y
	)

	# ratio_raw =
	# floor(
	#     minor_delta * 256
	#     /
	#     major_delta
	# )
	var ratio_raw := (
		minor_delta
		* FixedPoint.RAW_ONE
	) / major_delta

	# 将比例压缩成 0～31 的 bucket。
	var ratio_bucket := (
		mini(
			ratio_raw + 3,
			255
		)
		>> 3
	)

	# ratio bucket → ROM direction index
	var direction_index := (
		RATIO_TO_DIRECTION_INDEX[
			ratio_bucket
		]
	)

	# --------------------------------------------------------------------------
	# 极小角度量化成纯轴
	# --------------------------------------------------------------------------

	# 即使原始 position_delta 并不是纯轴，
	# 比例足够小时也可能得到 direction_index == 0。
	#
	# FC 此时主轴使用 ±256，而不是表中的 255。
	if direction_index == 0:
		var direction_raw := Vector2i.ZERO

		if abs_x > abs_y:
			direction_raw.x = (
				FixedPoint.RAW_ONE
					if position_delta.x > 0
					else -FixedPoint.RAW_ONE
			)
		else:
			direction_raw.y = (
				FixedPoint.RAW_ONE
					if position_delta.y > 0
					else -FixedPoint.RAW_ONE
			)

		return direction_raw

	# --------------------------------------------------------------------------
	# ROM 查表
	# --------------------------------------------------------------------------

	var minor_component_raw := (
		DIRECTION_SMALL_RAW[
			direction_index
		]
	)

	var major_component_raw := (
		DIRECTION_LARGE_RAW[
			direction_index
		]
	)

	var direction_raw := Vector2i.ZERO

	# 原始坐标差较大的轴使用 major，
	# 较小的轴使用 minor。
	if abs_x > abs_y:
		direction_raw.x = major_component_raw
		direction_raw.y = minor_component_raw
	else:
		direction_raw.x = minor_component_raw
		direction_raw.y = major_component_raw

	# 恢复原始 X / Y 方向符号。
	if position_delta.x < 0:
		direction_raw.x = -direction_raw.x

	if position_delta.y < 0:
		direction_raw.y = -direction_raw.y

	return direction_raw


# ==============================================================================
# Q8.8 运算
# ==============================================================================

## 两个有符号 Q8.8 raw 相乘。
##
## 返回值仍然是 Q8.8 raw。
##
## 当前显式处理正负号：
##
##     取绝对值
##         ↓
##     相乘
##         ↓
##     >> 8
##         ↓
##     恢复符号
##
## 如果以后继续追求 FC 乘法例程的逐指令一致，
## 可以只修改本函数。
static func _signed_q8_multiply(
	a_raw: int,
	b_raw: int
) -> int:
	var is_negative := (
		(a_raw < 0)
		!=
		(b_raw < 0)
	)

	var magnitude_raw := (
		absi(a_raw)
		* absi(b_raw)
	) >> 8

	return (
		-magnitude_raw
		if is_negative
		else magnitude_raw
	)


# ==============================================================================
# 输出转换
# ==============================================================================

## Q8.8 raw 速度 → 普通 Vector3 速度。
static func _raw_velocity_to_vector3(
	velocity_raw: Vector3i
) -> Vector3:
	return Vector3(
		FixedPoint.from_raw(velocity_raw.x),
		FixedPoint.from_raw(velocity_raw.y),
		FixedPoint.from_raw(velocity_raw.z)
	)
