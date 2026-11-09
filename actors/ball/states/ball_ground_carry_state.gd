extends BallState


const TARGET_X_OFFSET := 12.0


func enter(_data) -> void:

	# 携带期间足球 Z 不执行自身运动，
	# Z 高度由持球角色同步。
	ball.ball_z_movement.gravity_disable()
	#ball.ball_horizontal_movement.stop_immediately()
	ball.ball_z_movement.z_velocity_raw = 0


func exit() -> void:
	ball.ball_horizontal_movement.clear_position_sync()
	pass


func logic_tick() -> void:
	# --------------------------------------------------------------------------
	# 没有持球角色
	# --------------------------------------------------------------------------

	if ball.carrier == null:
		request_state(State.FREE)
		return


	# --------------------------------------------------------------------------
	# 获取角色数据
	# --------------------------------------------------------------------------

	var player_position: Vector2i = (
		ball.carrier.get_horizontal_position_integer()
	)

	var facing_direction: Vector2 = (
		ball.carrier.get_facing_direction()
	)

	var target_position := Vector2i(
		player_position.x
			+ facing_direction.x * TARGET_X_OFFSET,

		player_position.y
			+ Ball.PLAYER_CONTROL_Y_OFFSET
	)


	ball.ball_horizontal_movement.set_horizontal_velocity(ball.carrier.get_horizontal_velocity())
	ball.ball_horizontal_movement.sync_position(target_position)

	ball.ball_z_movement.sync_integer_height(
		ball.carrier.get_z_height_integer()
	)
