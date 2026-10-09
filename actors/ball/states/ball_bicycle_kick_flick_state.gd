
class_name BallBicycleKickFlickState
extends BallState


## FC $14/$94：倒钩前的足球挑起阶段。
##
## 已确认的初始化流程：
## 1. 保存足球原始 XYZ 坐标。
## 2. 通过 $AF94 根据角色位置与动作偏移生成临时持球位置。
## 3. 复制角色水平速度，计算 XYZ 整数坐标差。
## 4. 根据坐标差生成足球新速度。
## 5. 恢复足球原来的整数位置，保留子像素。
## 6. 使用新速度正式积分一次。
##
## 注意：
## $14 的后续状态切换和特殊运动规则尚未完全逆向。
## 目前后续水平运动使用 BallHorizontalMovement 默认积分。


const RAW_ONE: int = 256

const VELOCITY_CORRECTION_RAW: int = 32
const BASE_Z_VELOCITY_RAW: int = 0x0400
const GRAVITY_RAW: int = 0x0080

## FC 动作 $46 的基础携带偏移。
##
## 朝右：X = -8
## 朝左：X = +8（镜像规则，仍需 FC 验证）
##
## Y、Z 不随水平朝向改变。
const BICYCLE_KICK_FLICK_OFFSET := Vector3i(8, -1, 24)


func enter(_data = null) -> void:
	
	ball.ball_z_movement.gravity_enable()

	_initialize_action_14()


func exit() -> void:
	pass


func physics_tick() -> void:
	# $14 后续特殊行为尚未完全确认。
	# 水平位移暂由 BallHorizontalMovement 负责。
	pass


## FC $14 首次初始化。
func _initialize_action_14() -> void:
	var player = ball.carrier

	if player == null:
		push_warning(
			"BallBicycleKickFlickState: 进入时没有 carrier"
		)
		return

	var horizontal = ball.ball_horizontal_movement
	var z_movement = ball.ball_z_movement

	# ==================================================
	# 1. 保存足球原始 XYZ 坐标
	# ==================================================

	var old_xy_raw: Vector2i = (
		horizontal.get_horizontal_position_raw()
	)

	var old_x_raw: int = _wrap_signed24(old_xy_raw.x)
	var old_y_raw: int = _wrap_signed24(old_xy_raw.y)
	var old_z_raw: int = _wrap_signed24(
		z_movement.z_height_raw
	)

	var old_x_int: int = old_x_raw >> 8
	var old_y_int: int = old_y_raw >> 8
	var old_z_int: int = old_z_raw >> 8

	# 保留足球原有的低 8 位子像素。
	var old_x_frac: int = old_x_raw & 0xFF
	var old_y_frac: int = old_y_raw & 0xFF
	var old_z_frac: int = old_z_raw & 0xFF

	# ==================================================
	# 2. 读取角色当前逻辑位置与速度
	# ==================================================

	var player_position: Vector2 = (
		player.get_logical_position()
	)

	var player_velocity: Vector2 = (
		player.get_horizontal_velocity()
	)

	var player_z_height: float = (
		player.get_z_height()
	)

	var facing_direction: Vector2 = (
		player.get_facing_direction()
	)

	# FC 整数坐标。
	var player_x_int: int = FixedPoint.to_integer(
		player_position.x
	)

	var player_y_int: int = FixedPoint.to_integer(
		player_position.y
	)

	var player_z_int: int = FixedPoint.to_integer(
		player_z_height
	)

	# Q8.8 水平速度。
	var player_vx_raw: int = _wrap_signed16(
		FixedPoint.to_raw(player_velocity.x)
	)

	var player_vy_raw: int = _wrap_signed16(
		FixedPoint.to_raw(player_velocity.y)
	)

	# ==================================================
	# 3. 根据角色朝向生成携带偏移
	# ==================================================

	var offset: Vector3i = _get_flick_offset(
		facing_direction
	)

	# ==================================================
	# 4. FC $AF94：生成临时持球位置
	#
	# 整数部分来自 Player + 动作偏移。
	# 低 8 位保留足球原有子像素。
	# ==================================================

	var trial_x_raw: int = _wrap_signed24(
		(player_x_int + offset.x) * RAW_ONE
		+ old_x_frac
	)

	var trial_y_raw: int = _wrap_signed24(
		(player_y_int + offset.y) * RAW_ONE
		+ old_y_frac
	)

	var trial_z_raw: int = _wrap_signed24(
		(player_z_int + offset.z) * RAW_ONE
		+ old_z_frac
	)

	var trial_x_int: int = trial_x_raw >> 8
	var trial_y_int: int = trial_y_raw >> 8
	var trial_z_int: int = trial_z_raw >> 8

	# $AF94 复制角色水平速度。
	var trial_vx_raw: int = player_vx_raw
	var trial_vy_raw: int = player_vy_raw

	# ==================================================
	# 5. FC signed8 整数坐标差
	# ==================================================

	var dx8: int = _signed8(
		old_x_int - trial_x_int
	)

	var dy8: int = _signed8(
		old_y_int - trial_y_int
	)

	var dz8: int = _signed8(
		old_z_int - trial_z_int + 8
	)

	# ==================================================
	# 6. FC $14：生成足球速度
	# ==================================================

	var new_vx_raw: int = _wrap_signed16(
		trial_vx_raw
		- dx8 * VELOCITY_CORRECTION_RAW
	)

	var new_vy_raw: int = _wrap_signed16(
		trial_vy_raw
		- dy8 * VELOCITY_CORRECTION_RAW
	)

	var new_vz_raw: int = _wrap_signed16(
		BASE_Z_VELOCITY_RAW
		- dz8 * VELOCITY_CORRECTION_RAW
	)

	# ==================================================
	# 7. 恢复旧整数坐标，保留试算子像素
	# ==================================================

	var restored_x_raw: int = _wrap_signed24(
		(old_x_raw & ~0xFF)
		| (trial_x_raw & 0xFF)
	)

	var restored_y_raw: int = _wrap_signed24(
		(old_y_raw & ~0xFF)
		| (trial_y_raw & 0xFF)
	)

	var restored_z_raw: int = _wrap_signed24(
		(old_z_raw & ~0xFF)
		| (trial_z_raw & 0xFF)
	)

	# ==================================================
	# 8. 正式积分一次
	# ==================================================

	var final_x_raw: int = _wrap_signed24(
		restored_x_raw + new_vx_raw
	)

	var final_y_raw: int = _wrap_signed24(
		restored_y_raw + new_vy_raw
	)

	var final_z_raw: int = _wrap_signed24(
		restored_z_raw + new_vz_raw
	)

	var final_vz_raw: int = _wrap_signed16(
		new_vz_raw - GRAVITY_RAW
	)

	# ==================================================
	# 9. 写回足球运动组件
	# ==================================================

	horizontal.set_horizontal_position_raw(
		Vector2i(final_x_raw, final_y_raw)
	)

	horizontal.set_horizontal_velocity_raw(
		Vector2i(new_vx_raw, new_vy_raw)
	)

	z_movement.z_height_raw = final_z_raw
	z_movement.z_velocity_raw = final_vz_raw

	# ==================================================
	# 10. 调试输出
	# ==================================================

	print("\n========== FC ACTION $14 ==========")

	print(
		"OLD POSITION RAW: ",
		Vector3i(old_x_raw, old_y_raw, old_z_raw)
	)

	print(
		"PLAYER POSITION INT: ",
		Vector3i(
			player_x_int,
			player_y_int,
			player_z_int
		)
	)

	print("CARRY OFFSET: ", offset)

	print(
		"TRIAL POSITION RAW: ",
		Vector3i(
			trial_x_raw,
			trial_y_raw,
			trial_z_raw
		)
	)

	print(
		"TRIAL VELOCITY RAW: ",
		Vector2i(trial_vx_raw, trial_vy_raw)
	)

	print(
		"DX8 / DY8 / DZ8: ",
		Vector3i(dx8, dy8, dz8)
	)

	print(
		"NEW VELOCITY RAW: ",
		Vector3i(
			new_vx_raw,
			new_vy_raw,
			new_vz_raw
		)
	)

	print(
		"FINAL POSITION RAW: ",
		Vector3i(
			final_x_raw,
			final_y_raw,
			final_z_raw
		)
	)

	print(
		"FINAL VELOCITY RAW: ",
		Vector3i(
			new_vx_raw,
			new_vy_raw,
			final_vz_raw
		)
	)

	print("===================================\n")


## 根据角色水平朝向获取实际携带偏移。
func _get_flick_offset(
	facing_direction: Vector2
) -> Vector3i:
	var x_direction: int = -1

	if facing_direction.x < 0.0:
		x_direction = 1

	return Vector3i(
		BICYCLE_KICK_FLICK_OFFSET.x * x_direction,
		BICYCLE_KICK_FLICK_OFFSET.y,
		BICYCLE_KICK_FLICK_OFFSET.z
	)


## FC signed8。
func _signed8(value: int) -> int:
	value &= 0xFF

	if value >= 0x80:
		return value - 0x100

	return value


## FC signed16 回绕。
func _wrap_signed16(value: int) -> int:
	value &= 0xFFFF

	if value >= 0x8000:
		return value - 0x10000

	return value


## FC signed24 回绕。
func _wrap_signed24(value: int) -> int:
	value &= 0xFFFFFF

	if value >= 0x800000:
		return value - 0x1000000

	return value
