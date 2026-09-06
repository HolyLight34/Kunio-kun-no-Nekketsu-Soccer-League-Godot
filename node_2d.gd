extends Node2D
class_name PassCalculator
# =============================================================================
# FC 传球距离参数表
#
# ROM:
#   $0100
#   $0200
#   $0200
#   $0300
#   $0400
#   $0500
#   $0600
#   $0600
#
# 这些值是 ROM 原始 16 位参数。
# 虽然数值形式看起来类似 8.8：
#
#   $0100 = 256
#   $0200 = 512
#
# 但目前不要把它直接理解成最终球速 1.0 / 2.0。
# 它还会参与后续 $9867 的乘法计算。
# =============================================================================
const PASS_DISTANCE_SCALES_RAW: Array[int] = [
	0x0100,
	0x0200,
	0x0200,
	0x0300,
	0x0400,
	0x0500,
	0x0600,
	0x0600,
]
# =============================================================================
# 获取传球准备数据
#
# 参数：
#
# target_position_raw
#   目标角色的 8.8 raw 水平位置
#
# ball_position_raw
#   足球的 8.8 raw 水平位置
#
# 例如：
#
#   100.5 像素
#   raw = 100.5 * 256
#       = 25728
#
#
# FC 原版在 $F691 中不会直接使用完整 8.8 坐标。
#
# 它使用：
#
#   X 整数高/低字节
#   Y 整数高/低字节
#
# 而不会读取子像素低字节。
#
# 因此这里必须先分别把 target 和 ball 转成整数像素，
# 然后再做减法。
#
#
# 返回：
#
# final_delta
#   FC 实际参与方向 / 距离计算的整数像素差
#
# final_direction
#   FC 方向编码，例如：
#   $00 / $20 / $40 / $60 / ...
#
# q
#   粗略距离值
#
# table_offset
#   ROM 表中的字节偏移：
#   0, 2, 4, 6, ..., 14
#
# distance_class
#   Godot 数组索引：
#   0..7
#
# scale_raw
#   距离参数表返回的 ROM 原始值
# =============================================================================
func get_pass_setup_data(
	target_position_raw: Vector2i,
	ball_position_raw: Vector2i
) -> Dictionary:
	# -------------------------------------------------------------------------
	# 1. 模拟 FC：
	#    先分别丢弃 target / ball 的 8.8 子像素部分
	#
	#    不能先做：
	#
	#       target_raw - ball_raw
	#
	#    再 >> 8。
	#
	#    因为 FC 的实际顺序是：
	#
	#       target_integer
	#       ball_integer
	#              ↓
	#       target_integer - ball_integer
	# -------------------------------------------------------------------------
	var target_position_integer := _raw_position_to_integer(
		target_position_raw
	)
	var ball_position_integer := _raw_position_to_integer(
		ball_position_raw
	)
	# -------------------------------------------------------------------------
	# 2. $F691：
	#    计算有符号整数坐标差
	# -------------------------------------------------------------------------
	var final_delta := (
		target_position_integer
		- ball_position_integer
	)
	# -------------------------------------------------------------------------
	# 3. 根据整数 delta 计算距离档位
	# -------------------------------------------------------------------------
	var distance_data := get_pass_distance_data(
		final_delta
	)
	# -------------------------------------------------------------------------
	# 4. 返回后续轨迹算法需要的准备数据
	# -------------------------------------------------------------------------
	return {
		"final_delta": final_delta,

		"final_direction": direction_from(
			final_delta
		),

		"q": distance_data["q"],

		"table_offset": distance_data["table_offset"],

		"distance_class": distance_data["distance_class"],

		"scale_raw": distance_data["scale_raw"],
	}
# =============================================================================
# 计算 FC 传球距离档位
#
# 输入：
#
# delta
#   已经去掉子像素后的整数像素差。
#
#
# 公式：
#
# q =
#
#   floor(abs(dx) / 16)
#   +
#   floor(abs(dy) / 16)
#
#
# ROM 等价：
#
#   abs(dx) >> 4
#   abs(dy) >> 4
#
#
# 然后：
#
#   min(q, 14)
#   & 0x0E
#
# 得到：
#
#   0, 2, 4, 6, 8, 10, 12, 14
#
#
# 最后 >> 1 转成数组索引：
#
#   0..7
# =============================================================================
func get_pass_distance_data(
	delta: Vector2i
) -> Dictionary:
	var q := (
		(absi(delta.x) >> 4)
		+
		(absi(delta.y) >> 4)
	)
	# ROM 使用偶数字节偏移访问 16 位表。
	#
	# 例如：
	#
	# q = 7
	#
	# min(7, 14) = 7
	#
	# 7 & 0x0E = 6
	#
	# ROM offset = $06
	var table_offset := (
		mini(q, 14)
		& 0x0E
	)
	# Godot Array 不是按 byte offset 访问，
	# 因此把：
	#
	# 0,2,4,6,...14
	#
	# 转成：
	#
	# 0,1,2,3,...7
	var distance_class := (
		table_offset >> 1
	)
	var scale_raw := (
		PASS_DISTANCE_SCALES_RAW[
			distance_class
		]
	)
	return {
		"q": q,
		"table_offset": table_offset,
		"distance_class": distance_class,
		"scale_raw": scale_raw,
	}
# =============================================================================
# 8.8 raw 水平位置
# →
# FC 传球算法使用的整数像素位置
#
#
# 例如：
#
# raw:
#
#   100.75 * 256
#   = 25792
#
#
# >> 8：
#
#   25792 >> 8
#   = 100
#
#
# 这正好模拟 FC 在 $F691 中不读取子像素 byte 的行为。
# =============================================================================
func _raw_position_to_integer(
	position_raw: Vector2i
) -> Vector2i:

	return Vector2i(
		position_raw.x >> 8,
		position_raw.y >> 8
	)
# =============================================================================
# FC 方向计算
#
# 这里最终应该对应 $F691 后半段真正生成的方向编码。
#
# 返回值不是 Vector2.normalized()，
# 而是 FC 自己的方向编码。
#
# 例如你项目里如果已经确认：
#
#   $00 = UP
#   $20 = UP_RIGHT
#   $40 = RIGHT
#   $60 = DOWN_RIGHT
#   $80 = DOWN
#   $A0 = DOWN_LEFT
#   $C0 = LEFT
#   $E0 = UP_LEFT
#
# 就让这里返回对应 int。
#
#
# 注意：
#
# $F691 里面不仅仅是在做简单的 8 方向 atan 判断，
# 它后面还会生成给轨迹乘法使用的数据。
#
# 所以这里暂时只表示：
#
#   “最终方向编码”
#
# 不要把它和后续 VX/VY 用的方向分量混为一谈。
# =============================================================================
func direction_from(
	delta: Vector2i
) -> int:
	# TODO:
	# 这里替换成你已经逆向完成的 FC direction_from。
	#
	# 当前先给一个最简单的占位版本，
	# 方便整个脚本可以运行。
	#
	# 等我们继续把 $F691 的 F7F8 / F813 / F86B 等逻辑
	# 完整还原后，再替换成 bit-exact 版本。
	if delta == Vector2i.ZERO:
		return 0x00
	var x := delta.x
	var y := delta.y
	if x == 0:
		if y < 0:
			return 0x00
		else:
			return 0x80
	if y == 0:
		if x > 0:
			return 0x40
		else:
			return 0xC0
	if x > 0:
		if y < 0:
			return 0x20
		else:
			return 0x60
	else:
		if y < 0:
			return 0xE0
		else:
			return 0xA0
