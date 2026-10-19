
class_name FCShapeParser
extends RefCounted


## 将无符号字节解释为有符号 8 位整数。
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
static func get_x_bounds(
	shape: FCShape,
	facing_right: bool = true
) -> Vector2:
	if shape == null or not shape.is_valid():
		return Vector2.ZERO

	var raw := shape.raw_data

	if facing_right:
		return Vector2(
			-float(raw[1]),
			float(raw[0])
		)

	return Vector2(
		-float(raw[0]),
		float(raw[1])
	)


## 返回 Y 轴范围。
## 当前近似规则：P2 作为对称半径。
static func get_y_bounds(shape: FCShape) -> Vector2:
	if shape == null or not shape.is_valid():
		return Vector2.ZERO

	var radius := float(shape.raw_data[2])

	return Vector2(-radius, radius)


## 返回 Z 轴范围。
## 当前近似规则：P3 为正方向上限，P4 为有符号下限。
static func get_z_bounds(shape: FCShape) -> Vector2:
	if shape == null or not shape.is_valid():
		return Vector2.ZERO

	var raw := shape.raw_data

	return Vector2(
		float(signed_byte(raw[4])),
		float(raw[3])
	)


## 返回矩形所需的 XY 数据。
## position 为矩形中心，size 为完整宽高。
static func get_rectangle_data(
	shape: FCShape,
	facing_right: bool = true
) -> Dictionary:
	if shape == null or not shape.is_valid():
		return {
			"position": Vector2.ZERO,
			"size": Vector2.ZERO
		}

	var x_bounds := get_x_bounds(shape, facing_right)
	var y_bounds := get_y_bounds(shape)

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
