## FC 通用方向计算器。
##
## 根据起点和目标点，按照 FC 原版使用的方向量化规则，
## 计算一个 Q8.8 方向向量。
##
## 该算法目前已确认被以下逻辑共用：
## - 传球
## - 射门朝球门方向计算
##
## FC 并不使用 Vector2.normalized()。
##
## 方向计算流程：
##
##     起点 / 目标点
##          ↓
##     转换为整数坐标
##          ↓
##     计算 dx / dy
##          ↓
##     计算小轴 / 大轴比例
##          ↓
##     ratio bucket
##          ↓
##     ROM 查表
##          ↓
##     Q8.8 方向向量
##
## 本类是无状态静态算法类：
## - 不保存足球状态
## - 不修改足球
## - 不负责速度
## - 不负责传球
## - 不负责射门
## - 不负责位置更新
##
## 对外提供两个接口：
##
## calculate_raw()
##     返回 FC 原始 Q8.8 方向。
##     适合仍然需要继续进行定点运算的算法。
##
## calculate()
##     返回普通 Vector2。
##     适合普通 Godot 逻辑使用。
##
class_name FCDirectionCalculator
extends RefCounted


# ==============================================================================
# FC 方向量化 ROM 表
# ==============================================================================

## ratio bucket → direction index
##
## ratio bucket 范围：
##
##     0 ～ 31
##
## 得到的 direction index 用于查询下面两张方向分量表。
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

## 根据起点和目标点计算 FC 量化方向。
##
## 参数：
## - from_position：起点逻辑位置。
## - to_position：目标逻辑位置。
##
## 返回：
##     普通 Vector2 方向。
##
## 注意：
## 返回结果不是 Vector2.normalized() 的结果。
##
## 例如 FC 的精确 45°：
##
##     raw = (179, 179)
##
## 返回：
##
##     (179 / 256, 179 / 256)
##
## 约：
##
##     (0.69921875, 0.69921875)
##
static func calculate(
	from_position: Vector2,
	to_position: Vector2
) -> Vector2:
	var direction_raw := calculate_raw(
		from_position,
		to_position
	)

	return Vector2(
		FixedPoint.from_raw(direction_raw.x),
		FixedPoint.from_raw(direction_raw.y)
	)


## 根据起点和目标点计算 FC 原始 Q8.8 方向。
##
## 返回：
##
##     Vector2i(
##         direction_x_raw,
##         direction_y_raw
##     )
##
## 例如：
##
## 向右：
##
##     (256, 0)
##
## 向左：
##
##     (-256, 0)
##
## 45°右下：
##
##     (179, 179)
##
## 该接口适合传球等后续还需要继续进行 Q8.8 运算的算法。
static func calculate_raw(
	from_position: Vector2,
	to_position: Vector2
) -> Vector2i:
	# FC 先分别取得起点和目标点的整数坐标，
	# 再计算坐标差。
	#
	# 不能先：
	#
	#     to_position - from_position
	#
	# 然后再整体取整。
	var from_integer := FixedPoint.vector_to_integer(
		from_position
	)

	var to_integer := FixedPoint.vector_to_integer(
		to_position
	)

	var position_delta := (
		to_integer
		- from_integer
	)

	return calculate_raw_from_delta(
		position_delta
	)


## 根据已经计算好的整数坐标差生成 FC Q8.8 方向。
##
## 这个接口主要提供给：
## 已经完成 FC 整数坐标转换的底层算法使用。
##
## 普通调用方优先使用 calculate() 或 calculate_raw()。
static func calculate_raw_from_delta(
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
	#
	#     (0, ±256)
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
	#
	#     (±256, 0)
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
	#
	#     (±179, ±179)
	#
	# 而不是现代 normalized() 得到的约：
	#
	#     (±181, ±181)
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
	#
	#     floor(
	#         minor_delta * 256
	#         /
	#         major_delta
	#     )
	var ratio_raw := (
		minor_delta
		* FixedPoint.RAW_ONE
	) / major_delta

	# FC 将比例压缩成 0～31 的 bucket：
	#
	#     min(ratio_raw + 3, 255) >> 3
	var ratio_bucket := (
		mini(
			ratio_raw + 3,
			255
		)
		>> 3
	)

	# ratio bucket
	#     ↓
	# ROM direction index
	var direction_index := (
		RATIO_TO_DIRECTION_INDEX[
			ratio_bucket
		]
	)

	# --------------------------------------------------------------------------
	# 极小角度量化成纯轴
	# --------------------------------------------------------------------------
	#
	# 即使原始 position_delta 并不是纯轴，
	# 比例足够小时仍然可能得到：
	#
	#     direction_index == 0
	#
	# FC 此时主轴使用 ±256，
	# 而不是 DIRECTION_LARGE_RAW[0] 中的 255。
	# --------------------------------------------------------------------------

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

	# 恢复 X / Y 原始符号。
	if position_delta.x < 0:
		direction_raw.x = -direction_raw.x

	if position_delta.y < 0:
		direction_raw.y = -direction_raw.y

	return direction_raw
