## FC 传球目标检测组件。
##
## 负责：
## - 根据传球方向调整队友搜索区域。
## - 从当前搜索区域内寻找最佳接球队友。
## - 按 FC 固定球队成员顺序进行候选比较。
## - 根据 FC 距离评分规则选择目标。
## - 没有合适队友时，根据足球位置、搜索方向和角色朝向
##   生成 FC 默认传球目标。
##
## 本组件只负责决定“传到哪里”。
## 足球最终如何根据目标位置生成传球轨迹，
## 由 Ball / PassTrajectoryCalculator 负责。
class_name PassTargetDetector
extends Area2D


# ==============================================================================
# 外部依赖
# ==============================================================================

## 当前执行传球的角色。
##
## 用于：
## - 排除自己
## - 获取当前位置
## - 获取角色面朝方向
@export var player: Player


## 队友列表。
##
## 必须按照 FC 固定的球队成员扫描顺序保存。
##
## FC 在距离评分相同时使用 <=，
## 因此后扫描到的角色会覆盖之前的角色。
var teammates: Array[Player] = []


# ==============================================================================
# 常量
# ==============================================================================

## 无人接应时默认传球目标与足球之间的距离。
##
## 水平：
##
##     96
##
## 45°：
##
##     int(96 * 0.707106...)
##     = 67
const DEFAULT_PASS_DISTANCE: float = 96.0


# ==============================================================================
# FC 距离评分 ROM 表
# ==============================================================================

## 比例桶（0～31）→ 角度索引（0～32）。
const DISTANCE_RATIO_TO_ANGLE: Array[int] = [
	0, 1, 2, 4, 5, 6, 8, 9,
	10, 11, 12, 13, 14, 16, 17, 18,
	19, 20, 21, 22, 23, 24, 25, 26,
	27, 28, 28, 29, 30, 31, 31, 32,
]


## 角度索引（0～32）
## →
## Q8.8 距离修正系数低字节。
##
## 完整修正系数：
##
##     256 + 此值
const DISTANCE_CORRECTION_LOW: Array[int] = [
	0, 0, 0, 0, 0, 1, 2, 3,
	4, 5, 7, 8, 10, 15, 16, 20,
	21, 24, 26, 28, 33, 36, 38, 45,
	49, 56, 60, 64, 73, 77, 88, 99,
	105,
]


# ==============================================================================
# 对外接口
# ==============================================================================

## 设置当前传球目标搜索方向。
##
## CollisionPolygon2D 默认朝右，因此直接使用方向角度
## 旋转整个搜索区域。
##
## 这里只改变真实的搜索方向。
## 角色 facing 不会影响搜索区域方向。
func set_search_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	rotation = direction.angle()


## 获取当前传球的最终目标位置。
##
## 找到合适的接球队友：
##     返回该队友的逻辑位置。
##
## 没有找到接球队友：
##     根据足球当前位置生成 FC 默认目标位置。
##
## ball_position：
##     足球当前逻辑 XY 位置。
func get_pass_target_position(
	ball_position: Vector2
) -> Vector2:
	var target := _find_best_pass_target()

	if target != null:
		return target.get_logical_position()

	return _calculate_default_target_position(
		ball_position
	)


# ==============================================================================
# 目标搜索
# ==============================================================================

## 从当前搜索区域内选择最佳接球队友。
func _find_best_pass_target() -> Player:
	# Area2D 只负责告诉我们当前有哪些对象处于搜索区域。
	#
	# 最终扫描顺序不能依赖 get_overlapping_bodies()，
	# 因为 FC 使用固定球队成员顺序。
	var candidates: Dictionary = {}

	for body: Node2D in get_overlapping_bodies():
		if body is Player:
			candidates[body] = true

	# FC 先分别取得双方整数坐标，
	# 再计算坐标差。
	var player_position_integer := FixedPoint.vector_to_integer(
		player.get_logical_position()
	)

	var best_target: Player = null
	var best_score: int = 32767

	# 必须按照 FC 固定球队成员顺序扫描。
	for teammate: Player in teammates:
		if teammate == player:
			continue

		if not candidates.has(teammate):
			continue

		var teammate_position_integer := FixedPoint.vector_to_integer(
			teammate.get_logical_position()
		)

		var position_delta := (
			teammate_position_integer
			- player_position_integer
		)

		var score := _calculate_distance_score(
			position_delta
		)

		# FC 使用 <=。
		#
		# 因此评分相同时，
		# 后扫描到的角色覆盖之前的角色。
		if score <= best_score:
			best_score = score
			best_target = teammate

	return best_target


# ==============================================================================
# 默认目标
# ==============================================================================

## 计算无人接应时的 FC 默认目标位置。
##
## 默认目标：
##
##     足球整数位置 + 默认目标偏移
##
## 注意：
## 先将足球位置转换成 FC 整数坐标，
## 再加默认偏移。
func _calculate_default_target_position(
	ball_position: Vector2
) -> Vector2:
	var ball_position_integer := FixedPoint.vector_to_integer(
		ball_position
	)

	var default_offset := _calculate_default_target_offset()

	return Vector2(
		ball_position_integer
		+ default_offset
	)


## 计算无人接应时，相对于足球位置的默认目标偏移。
##
## 通常根据当前搜索方向生成。
##
## FC 特殊规则：
## 当搜索方向为纯上 / 纯下时，
## 默认目标的 X 方向由角色 facing 决定。
func _calculate_default_target_offset() -> Vector2i:
	var search_direction := _get_search_direction()

	var direction_x := signf(
		search_direction.x
	)

	var direction_y := signf(
		search_direction.y
	)

	# --------------------------------------------------------------------------
	# 纯上 / 纯下
	# --------------------------------------------------------------------------
	#
	# 搜索区域本身仍然保持正上 / 正下。
	#
	# 只有生成默认目标时，
	# X 方向才使用角色 facing。
	#
	# 例如：
	#
	# 搜索方向：UP
	# facing：RIGHT
	#
	# 最终默认偏移：
	#
	#     (67, -67)
	if is_zero_approx(search_direction.x):
		direction_x = signf(
			player.facing_direction.x
		)

	# --------------------------------------------------------------------------
	# 纯左 / 纯右
	# --------------------------------------------------------------------------

	if is_zero_approx(search_direction.y):
		return Vector2i(
			int(
				direction_x
				* DEFAULT_PASS_DISTANCE
			),
			0
		)

	# --------------------------------------------------------------------------
	# 斜方向
	# --------------------------------------------------------------------------
	#
	# 包括：
	# - 原本就是斜方向
	# - 纯上 / 纯下根据 facing 补出的斜方向
	var default_direction := Vector2(
		direction_x,
		direction_y
	).normalized()

	# FC 这里使用截断。
	#
	# 例如：
	#
	#     96 * 0.707106...
	#     = 67.88...
	#
	# int()
	#     ↓
	#     67
	return Vector2i(
		int(
			default_direction.x
			* DEFAULT_PASS_DISTANCE
		),
		int(
			default_direction.y
			* DEFAULT_PASS_DISTANCE
		)
	)


## 获取当前搜索区域代表的逻辑搜索方向。
##
## CollisionPolygon2D 默认朝右，
## 因此 Vector2.RIGHT 根据当前 rotation 旋转后，
## 就是当前真实搜索方向。
func _get_search_direction() -> Vector2:
	return Vector2.RIGHT.rotated(
		rotation
	)


# ==============================================================================
# FC 距离评分
# ==============================================================================

## 根据两个角色之间的 FC 整数坐标差计算距离评分。
##
## 评分越小，目标越近。
func _calculate_distance_score(
	position_delta: Vector2i
) -> int:
	var abs_x := absi(
		position_delta.x
	)

	var abs_y := absi(
		position_delta.y
	)

	var major_delta := maxi(
		abs_x,
		abs_y
	)

	var minor_delta := mini(
		abs_x,
		abs_y
	)

	if major_delta == 0:
		return 0

	# minor / major 转换成 Q8 比例。
	var ratio_raw := (
		minor_delta
		* FixedPoint.RAW_ONE
	) / major_delta

	# Q8 比例量化成 0～31。
	var ratio_bucket := (
		mini(
			ratio_raw + 3,
			255
		)
		>> 3
	)

	# 比例桶 → ROM 角度索引。
	var angle_index := DISTANCE_RATIO_TO_ANGLE[
		ratio_bucket
	]

	# Q8.8 距离修正系数。
	#
	# 高字节固定为 1：
	#
	#     256 + low
	var correction_raw := (
		FixedPoint.RAW_ONE
		+ DISTANCE_CORRECTION_LOW[
			angle_index
		]
	)

	# FC 最终距离评分。
	return (
		major_delta
		* correction_raw
	) >> 8
