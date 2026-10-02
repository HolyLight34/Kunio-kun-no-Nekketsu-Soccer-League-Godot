## FC 传球轨迹计算器。
##
## 根据足球当前位置、当前 Z 高度和目标位置，
## 按照 FC 原版传球规则计算足球的初始运动速度。
##
## 本类是无状态的静态算法类，只负责传球轨迹计算：
##
## - 不保存足球状态
## - 不修改足球
## - 不处理球权
## - 不切换足球状态
## - 不负责实际位置更新
##
## FC 共用的方向量化算法不属于传球本身，
## 由 FCDirectionCalculator 负责。
##
## 对外统一使用正常逻辑单位：
##
## - Vector2：水平位置
## - float：Z 高度
## - Vector3：最终初始速度
##
## FC 内部使用的：
##
## - 整数坐标
## - 1/256 定点数
## - 距离档位
## - Q8.8 乘法
##
## 均隐藏在本类内部。
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
##     64 raw = 0.25
const PASS_INITIAL_VZ_PER_FLIGHT_STEP_RAW: int = 64


# ==============================================================================
# 对外接口
# ==============================================================================

## 计算 FC 传球的初始速度。
##
## 参数：
##
## - ball_position：
##     足球当前水平逻辑位置。
##
## - ball_z_height：
##     足球当前逻辑 Z 高度。
##
## - target_position：
##     传球目标的水平逻辑位置。
##
## 返回：
##
##     Vector3(VX, VY, VZ)
##
## 调用方不需要知道内部使用的：
##
## - 1/256 定点数
## - 整数坐标
## - 距离档位
## - Q8.8 乘法
##
## FC 共用方向量化由 FCDirectionCalculator 负责。
static func calculate(
	ball_position: Vector2,
	ball_z_height: float,
	target_position: Vector2
) -> Vector3:
	# FC 传球先分别取得足球和目标的整数坐标，
	# 然后再计算两者之间的坐标差。
	#
	# 不能先计算浮点坐标差，
	# 再对结果取整。
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
	#
	#     floor(abs(dx) / 16)
	#     +
	#     floor(abs(dy) / 16)
	var distance_q := (
		(absi(position_delta.x) >> 4)
		+
		(absi(position_delta.y) >> 4)
	)

	# 近距离且足球位于地面高度：
	# 使用特殊贴地传球。
	if (
		distance_q <= 5
		and
		ball_z_integer == 0
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
	var direction_raw := (
		FCDirectionCalculator.calculate_raw_from_delta(
			position_delta
		)
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
	#     min(q, 14) & $0E
	#
	# 最终只会得到偶数：
	#
	#     0, 2, 4, 6, 8, 10, 12, 14
	var distance_index := (
		mini(distance_q, 14)
		& 0x0E
	)

	# ROM 索引：
	#
	#     0, 2, 4, 6...
	#
	# Godot Array 索引：
	#
	#     0, 1, 2, 3...
	var pass_speed_raw := PASS_SPEED_RAW[
		distance_index >> 1
	]

	# 根据目标坐标差，
	# 使用共用 FC 方向算法生成 Q8.8 方向。
	var direction_raw := (
		FCDirectionCalculator.calculate_raw_from_delta(
			position_delta
		)
	)

	# Q8.8 direction × Q8.8 speed
	#
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
	#
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
	# 如果触发，说明方向、速度，
	# 或尚未逆向出的特殊情况存在问题。
	assert(
		dominant_speed_raw > 0,
		"Pass dominant speed must be greater than zero."
	)

	# dominant_distance：
	#
	#     整数像素
	#
	# dominant_speed_raw：
	#
	#     1/256 像素 / logic tick
	#
	# 所以：
	#
	# estimated_flight_steps =
	#
	#     floor(
	#         dominant_distance * 256
	#         /
	#         dominant_speed_raw
	#     )
	var estimated_flight_steps := (
		dominant_distance
		* FixedPoint.RAW_ONE
	) / dominant_speed_raw

	# --------------------------------------------------------------------------
	# 计算初始 Z 速度
	# --------------------------------------------------------------------------
	#
	# 每增加一个预计飞行 Tick：
	#
	#     VZ += 64 raw
	#
	# 最大：
	#
	#     VZ = 4096 raw = 16.0

	var z_velocity_raw := mini(
		estimated_flight_steps
		* PASS_INITIAL_VZ_PER_FLIGHT_STEP_RAW,
		MAX_PASS_Z_VELOCITY_RAW
	)

	# 当前足球高度修正。
	#
	# ball_z_integer =
	#
	#     current_ball_z_raw >> 8
	#
	# VZ_raw -=
	#
	#     floor(ball_z_integer / 16) * 256
	#
	# 足球当前越高，
	# 新生成的向上速度越低。
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
