## 1/256 定点数转换工具。
##
## 统一负责游戏逻辑中浮点值、1/256 定点整数以及整数坐标之间的转换，
## 隐藏定点数的缩放比例和具体转换方式。
##
## 项目中的运动组件可以在内部使用 raw 保存权威数据，
## 对外接口通常使用 float / Vector2。
## 当具体算法需要重新获得 FC 定点数或整数坐标时，
## 应通过本类进行统一转换。
##
## 本类只负责数值表示转换，不包含角色、足球、传球等具体游戏规则。
class_name FixedPoint
extends RefCounted


## 一个逻辑单位包含的 raw 子单位数量。
const RAW_ONE: int = 256


# ==============================================================================
# 标量转换
# ==============================================================================

## 浮点值 → 1/256 raw。
static func to_raw(value: float) -> int:
	return roundi(value * RAW_ONE)


## 1/256 raw → 浮点值。
static func from_raw(value: int) -> float:
	return float(value) / RAW_ONE


## 取得 1/256 raw 的整数部分。
##
## 当前使用算术右移取得 raw 的高位。
## 对负数时其行为相当于向负无穷方向取得整数部分。
static func raw_to_integer(value: int) -> int:
	return value >> 8


## 浮点值 → 按定点规则取得整数部分。
##
## 先转换为 1/256 raw，再按照 raw 的整数部分规则进行转换。
static func to_integer(value: float) -> int:
	return raw_to_integer(
		to_raw(value)
	)


# ==============================================================================
# Vector2 转换
# ==============================================================================

## Vector2 → 1/256 raw Vector2i。
static func vector_to_raw(value: Vector2) -> Vector2i:
	return Vector2i(
		to_raw(value.x),
		to_raw(value.y)
	)


## 1/256 raw Vector2i → Vector2。
static func vector_from_raw(value: Vector2i) -> Vector2:
	return Vector2(
		from_raw(value.x),
		from_raw(value.y)
	)


## 取得 1/256 raw Vector2i 的整数坐标。
static func raw_vector_to_integer(value: Vector2i) -> Vector2i:
	return Vector2i(
		raw_to_integer(value.x),
		raw_to_integer(value.y)
	)


## Vector2 → 按定点规则取得整数坐标。
##
## 先转换为 1/256 raw，再按照 raw 的整数部分规则进行转换。
## 适用于模块之间使用 Vector2 传递位置，
## 但具体 FC 算法需要整数坐标的情况。
static func vector_to_integer(value: Vector2) -> Vector2i:
	return raw_vector_to_integer(
		vector_to_raw(value)
	)
