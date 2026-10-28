
class_name FCShapeParser
extends RefCounted


## 将无符号字节解释为有符号 8 位整数。
##
## 例如：
## $F8 -> -8
## $10 -> 16
## $00 -> 0
static func signed_byte(value: int) -> int:
	value = value & 0xFF

	if value >= 128:
		return value - 256

	return value


## 返回 X 轴范围：Vector2(最小值, 最大值)。
##
## facing_right = true:
##     X = [-P0, +P1]
##
## facing_right = false:
##     X = [-P1, +P0]
##
## P0 按有符号 8 位整数解析。
## P1 按无符号 8 位整数解析。
static func get_x_bounds(
	shape: FCShape,
	facing_right: bool = true
) -> Vector2:
	if shape == null or not shape.is_valid():
		return Vector2.ZERO

	var raw: PackedByteArray = shape.raw_data

	var p0: int = signed_byte(raw[0])
	var p1: int = int(raw[1])

	if facing_right:
		return Vector2(
			-float(p0),
			float(p1)
		)

	return Vector2(
		-float(p1),
		float(p0)
	)


## 返回 Y 轴范围。
##
## 当前采用对称半径近似：
##     Y = [-P2, +P2]
static func get_y_bounds(
	shape: FCShape
) -> Vector2:
	if shape == null or not shape.is_valid():
		return Vector2.ZERO

	var raw: PackedByteArray = shape.raw_data
	var radius: float = float(raw[2])

	return Vector2(
		-radius,
		radius
	)


## 返回 Shape 的近似局部 Z 区间。
##
## Raw5：
##     raw[3] = ZA，上侧坐标
##     raw[4] = ZB，带符号的下侧编码
##
## 转换规则：
##     下限 = -signed8(ZB)
##     上限 = ZA
##
## 例如 Shape $0F：
##     ZA = $14 = 20
##     ZB = $F4 = -12
##     局部Z区间 = [12, 20]
static func get_z_bounds(shape: FCShape) -> Vector2:
	if shape == null or not shape.is_valid():
		return Vector2.ZERO

	var raw: PackedByteArray = shape.raw_data

	var z_min := float(-signed_byte(raw[4]))
	var z_max := float(raw[3])

	return Vector2(z_min, z_max)

## 返回 XY 矩形数据。
##
## position：矩形中心。
## size：矩形完整宽度和高度。
##
## 这里只负责编辑器可视化，不代表完整的
## FC 三轴碰撞算法。
static func get_rectangle_data(
	shape: FCShape,
	facing_right: bool = true
) -> Dictionary:
	if shape == null or not shape.is_valid():
		return {
			"position": Vector2.ZERO,
			"size": Vector2.ZERO
		}

	var x_bounds: Vector2 = get_x_bounds(
		shape,
		facing_right
	)

	var y_bounds: Vector2 = get_y_bounds(shape)

	var minimum := Vector2(
		x_bounds.x,
		y_bounds.x
	)

	var maximum := Vector2(
		x_bounds.y,
		y_bounds.y
	)

	return {
		"position": (minimum + maximum) * 0.5,
		"size": maximum - minimum
	}
