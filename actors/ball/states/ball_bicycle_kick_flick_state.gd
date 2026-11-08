extends BallState


## FC $14/$94：倒钩前的足球挑起阶段。
##
## 已确认的初始化流程：
## 1. 保存足球进入$14前的XYZ坐标。
## 2. 根据角色位置和动作偏移生成临时携带位置。
## 3. 复制角色水平速度，并使用$46的+4.0垂直速度试算一次积分。
## 4. 比较原始坐标与试算坐标的整数部分。
## 5. 根据整数坐标差生成足球正式速度。
## 6. 恢复足球原来的整数位置，保留试算产生的子像素。
## 7. 使用新速度正式积分一次。
## 8. 对正式VZ应用一次重力。
##
## 足球$14/$94不会固定附着在角色身上。
## 角色动画后续发出$05事件时，足球会进入正式射门状态，
## 并由$05初始化覆盖当前挑球速度。


const RAW_ONE: int = 256

## 整数坐标差转换为Q8.8速度时的乘数。
##
## 32 raw = 0.125。
const VELOCITY_CORRECTION_RAW: int = 32

## $14生成垂直速度时使用的基础值。
##
## $0400 raw = +4.0。
const BASE_Z_VELOCITY_RAW: int = 0x0400

## 带球倒钩$46进入足球$14时，用于试算的垂直速度。
##
## $0400 raw = +4.0。
const TRIAL_Z_VELOCITY_RAW: int = 0x0400

## 足球重力。
##
## $0080 raw = 0.5。
const GRAVITY_RAW: int = 0x0080


## FC动作$46的基础携带偏移。
##
## 面向右：
##     X = -8
##     Y = -1
##     Z = +24
##
## 面向左：
##     X = +8
##     Y = -1
##     Z = +24
##
## X根据水平朝向镜像；Y和Z不镜像。
const BICYCLE_KICK_FLICK_OFFSET := Vector3i(
	8,
	-1,
	24
)


func enter(_data) -> void:
	ball.ball_z_movement.gravity_enable()

	_initialize_action_14()


func exit() -> void:
	pass


func logic_tick() -> void:
	# $14初始化完成后的后续逻辑，由足球水平运动和Z轴运动组件负责：
	#
	# 1. 使用当前VX/VY/VZ更新位置。
	# 2. 对VZ应用重力。
	# 3. 执行普通足球地面和负Z处理。
	#
	# 不要在这里再次执行_initialize_action_14()。
	pass


## FC足球动作$14首次初始化。
func _initialize_action_14() -> void:
	var player = ball.carrier

	if player == null:
		push_warning(
			"BallBicycleKickFlickState: 进入$14时没有carrier"
		)
		return

	var horizontal = ball.ball_horizontal_movement
	var z_movement = ball.ball_z_movement

	# ==================================================
	# 1. 保存足球进入$14前的原始坐标
	# ==================================================

	var old_xy_raw: Vector2i = (
		horizontal.get_horizontal_position_raw()
	)

	var old_x_raw: int = _wrap_signed24(
		old_xy_raw.x
	)

	var old_y_raw: int = _wrap_signed24(
		old_xy_raw.y
	)

	var old_z_raw: int = _wrap_signed24(
		z_movement.z_height_raw
	)

	var old_x_int: int = old_x_raw >> 8
	var old_y_int: int = old_y_raw >> 8
	var old_z_int: int = old_z_raw >> 8

	# 保存原始低8位子像素。
	#
	# 原版之后会恢复原始整数部分，
	# 但保留试算积分产生的低8位。
	var old_x_frac: int = old_x_raw & 0xFF
	var old_y_frac: int = old_y_raw & 0xFF
	var old_z_frac: int = old_z_raw & 0xFF


	# ==================================================
	# 2. 读取角色当前逻辑位置
	# ==================================================

	var player_position: Vector2 = (
		player.get_logical_position()
	)

	var player_z_height: float = (
		player.get_z_height()
	)

	var player_x_int: int = FixedPoint.to_integer(
		player_position.x
	)

	var player_y_int: int = FixedPoint.to_integer(
		player_position.y
	)

	var player_z_int: int = FixedPoint.to_integer(
		player_z_height
	)


	# ==================================================
	# 3. 读取角色当前水平速度
	# ==================================================

	var player_velocity: Vector2 = (
		player.get_horizontal_velocity()
	)

	var player_vx_raw: int = _wrap_signed16(
		FixedPoint.to_raw(player_velocity.x)
	)

	var player_vy_raw: int = _wrap_signed16(
		FixedPoint.to_raw(player_velocity.y)
	)


	# ==================================================
	# 4. 根据角色朝向取得携带偏移
	# ==================================================

	var facing_direction: Vector2 = (
		player.get_facing_direction()
	)

	var offset: Vector3i = _get_flick_offset(
		facing_direction
	)


	# ==================================================
	# 5. 生成临时携带位置
	#
	# 这是Player整数坐标加动作偏移的位置。
	# 这里还没有执行试算积分。
	#
	# 低8位先继承足球进入$14前的子像素。
	# ==================================================

	var carry_x_raw: int = _wrap_signed24(
		(player_x_int + offset.x) * RAW_ONE
		+ old_x_frac
	)

	var carry_y_raw: int = _wrap_signed24(
		(player_y_int + offset.y) * RAW_ONE
		+ old_y_frac
	)

	var carry_z_raw: int = _wrap_signed24(
		(player_z_int + offset.z) * RAW_ONE
		+ old_z_frac
	)


	# ==================================================
	# 6. 准备试算速度
	#
	# 水平速度复制角色当前水平速度。
	#
	# 带球倒钩$46在进入$14时，角色初始化VZ为+4.0；
	# 足球试算同样使用+4.0。
	# ==================================================

	var trial_vx_raw: int = player_vx_raw
	var trial_vy_raw: int = player_vy_raw
	var trial_vz_raw: int = TRIAL_Z_VELOCITY_RAW


	# ==================================================
	# 7. 执行一次完整试算积分
	#
	# 之前的错误版本直接把carry位置当成trial位置，
	# 因此漏掉了trial_vz_raw=+4.0产生的Z位移，
	# 最终把初始VZ算成6.0而不是6.5。
	# ==================================================

	var trial_x_raw: int = _wrap_signed24(
		carry_x_raw + trial_vx_raw
	)

	var trial_y_raw: int = _wrap_signed24(
		carry_y_raw + trial_vy_raw
	)

	var trial_z_raw: int = _wrap_signed24(
		carry_z_raw + trial_vz_raw
	)

	var trial_x_int: int = trial_x_raw >> 8
	var trial_y_int: int = trial_y_raw >> 8
	var trial_z_int: int = trial_z_raw >> 8


	# ==================================================
	# 8. 计算FC signed8整数坐标差
	#
	# 所有差值都必须经过8位回绕和符号扩展。
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
	# 9. 根据试算整数位移生成正式速度
	#
	# new_vx_raw = trial_vx_raw - dx8 * 32
	# new_vy_raw = trial_vy_raw - dy8 * 32
	# new_vz_raw = $0400 - dz8 * 32
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
	# 10. 恢复进入$14前的整数坐标
	#
	# 高16位/整数部分恢复为old位置。
	# 低8位使用试算后的子像素。
	# ==================================================

	var restored_x_raw: int = _restore_integer_keep_trial_fraction(
		old_x_raw,
		trial_x_raw
	)

	var restored_y_raw: int = _restore_integer_keep_trial_fraction(
		old_y_raw,
		trial_y_raw
	)

	var restored_z_raw: int = _restore_integer_keep_trial_fraction(
		old_z_raw,
		trial_z_raw
	)


# ==================================================
# 11. 写回试算后的初始状态
#
# 不在这里执行正式积分，也不在这里减重力。
#
# 当前FC Logic Tick稍后的公共足球运动组件会负责：
#     position += velocity
#     vz -= gravity
# ==================================================

	horizontal.set_horizontal_position_raw(
	Vector2i(
		restored_x_raw,
		restored_y_raw
	)
)

	horizontal.set_horizontal_velocity_raw(
	Vector2i(
		new_vx_raw,
		new_vy_raw
	)
)

	z_movement.z_height_raw = restored_z_raw
	z_movement.z_velocity_raw = new_vz_raw

	# ==================================================
	# 14. 调试输出
	# ==================================================
	print(
	"INITIALIZED VELOCITY RAW: ",
	Vector3i(
		new_vx_raw,
		new_vy_raw,
		new_vz_raw
	)
)

	print(
	"RESTORED POSITION RAW: ",
	Vector3i(
		restored_x_raw,
		restored_y_raw,
		restored_z_raw
	)
)

	print(
	"EXPECTED AFTER COMMON PHYSICS: ",
	Vector3(
		float(restored_x_raw + new_vx_raw) / RAW_ONE,
		float(restored_y_raw + new_vy_raw) / RAW_ONE,
		float(restored_z_raw + new_vz_raw) / RAW_ONE
	)
)

	print(
	"EXPECTED VZ AFTER GRAVITY: ",
	float(new_vz_raw - GRAVITY_RAW) / RAW_ONE
)


## 根据角色水平朝向取得实际携带偏移。
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


## 恢复原始整数部分，同时保留试算后的低8位子像素。
func _restore_integer_keep_trial_fraction(
	old_raw: int,
	trial_raw: int
) -> int:
	return _wrap_signed24(
		(old_raw & ~0xFF)
		| (trial_raw & 0xFF)
	)


## FC signed8。
func _signed8(value: int) -> int:
	value &= 0xFF

	if value >= 0x80:
		return value - 0x100

	return value


## FC signed16回绕。
func _wrap_signed16(value: int) -> int:
	value &= 0xFFFF

	if value >= 0x8000:
		return value - 0x10000

	return value


## FC signed24回绕。
func _wrap_signed24(value: int) -> int:
	value &= 0xFFFFFF

	if value >= 0x800000:
		return value - 0x1000000

	return value
