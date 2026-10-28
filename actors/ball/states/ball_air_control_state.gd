extends BallState


const TARGET_X_OFFSET := 10.0
const X_CORRECTION_SPEED := 0.5


var player: Player


func enter(_data) -> void:
	player = ball.carrier

	ball.ball_z_movement.launch(
		player.get_z_velocity() + 0.5
	)


	


func physics_tick() -> void:
	var player_position := player.get_logical_position()
	var player_velocity := player.get_horizontal_velocity()
	var facing_direction := player.get_facing_direction()
	var player_z := player.get_z_height_integer()
	if ball.get_z_height_integer() <= player_z:
		change_state(State.GROUND_CARRY)
		return
	# --------------------------------------------------------------------------
	# X 目标位置
	#
	# 足球目标位于角色当前面朝方向前方 10 像素。
	# --------------------------------------------------------------------------

	var target_x := (
		player_position.x
		+ facing_direction.x * TARGET_X_OFFSET
	)

	var target_x_int := FixedPoint.to_integer(
		target_x
	)

	var ball_x_int := FixedPoint.to_integer(
		ball.get_logical_position().x
	)

	# --------------------------------------------------------------------------
	# X 速度
	#
	# 基础速度继承角色当前 X 速度。
	#
	# 足球位于目标左侧：
	#     +0.5
	#
	# 足球位于目标右侧：
	#     -0.5
	#
	# 整数 X 已经与目标一致：
	#     不进行额外修正。
	# --------------------------------------------------------------------------

	var x_velocity := player_velocity.x

	if ball_x_int < target_x_int:
		x_velocity += X_CORRECTION_SPEED

	elif ball_x_int > target_x_int:
		x_velocity -= X_CORRECTION_SPEED

	ball.ball_horizontal_movement.set_horizontal_velocity(
		Vector2(
			x_velocity,
			0.0
		)
	)

	# --------------------------------------------------------------------------
	# Y 位置
	#
	# 足球始终同步：
	#
	#     Player Y + 1
	# --------------------------------------------------------------------------

	ball.ball_horizontal_movement.set_y_position(
		player_position.y
		+ Ball.PLAYER_CONTROL_Y_OFFSET
	)


func exit() -> void:
	player = null
