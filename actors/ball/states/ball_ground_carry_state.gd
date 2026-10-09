extends BallState


const TARGET_X_OFFSET := 12.0


func enter(_data) -> void:
	ball.enable_hit()

	# 携带期间足球 Z 不执行自身运动，
	# Z 高度由持球角色同步。
	ball.ball_z_movement.gravity_disable()


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass
func uses_default_horizontal_step() -> bool:
	return false

func physics_tick() -> void:
	# --------------------------------------------------------------------------
	# 没有持球角色
	# --------------------------------------------------------------------------

	if ball.carrier == null:
		change_state(State.FREE)
		return


	# --------------------------------------------------------------------------
	# 获取角色数据
	# --------------------------------------------------------------------------

	var player_position: Vector2 = (
		ball.carrier.get_logical_position()
	)

	var player_velocity: Vector2 = (
		ball.carrier.get_horizontal_velocity()
	)

	var facing_direction: Vector2 = (
		ball.carrier.get_facing_direction()
	)


	# --------------------------------------------------------------------------
	# 计算携带位置
	#
	# X：
	#     角色面朝方向前方 12 像素
	#
	# Y：
	#     角色逻辑 Y + 控球偏移
	# --------------------------------------------------------------------------

	var target_position := Vector2(
		player_position.x
			+ facing_direction.x * TARGET_X_OFFSET,

		player_position.y
			+ Ball.PLAYER_CONTROL_Y_OFFSET
	)


	# --------------------------------------------------------------------------
	# 同步足球水平位置
	#
	# 携带期间足球保持在角色对应的控球位置。
	# --------------------------------------------------------------------------

	ball.ball_horizontal_movement.set_horizontal_position(
		target_position
	)
	

	# --------------------------------------------------------------------------
	# 同步足球水平速度
	#
	# FC 已确认：
	# 携带期间足球 VX / VY 与持球角色一致。
	#
	# 注意：
	# 这里只同步速度，不再执行 physics_step()。
	# 因为上面已经直接同步了足球位置。
	#
	# 保存这个速度非常重要：
	# 后续足球进入其他动作时，可以继续使用携带期间留下的 VX / VY。
	# --------------------------------------------------------------------------

	ball.ball_horizontal_movement.set_horizontal_velocity(
		player_velocity
	)

	# --------------------------------------------------------------------------
	# 同步角色 Z 整数高度
	#
	# 只同步整数部分，
	# 足球自身低 8 位子像素继续保留。
	# --------------------------------------------------------------------------

	ball.ball_z_movement.sync_integer_height(
		ball.carrier.get_z_height()
	)
