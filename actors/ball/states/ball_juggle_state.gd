extends BallState


const TARGET_X_OFFSET := 8.0
const X_CORRECTION_SPEED := 0.1875
const INITIAL_Z_VELOCITY := 3.0
const JUGGLE_DURATION_TICKS := 16


var player: Player


func enter(_data) -> void:
	player = ball.carrier

	ball.ball_z_movement.launch(
		INITIAL_Z_VELOCITY
	)

	ball.set_receivable_detection_enabled(false)

	ball.tick_timer_component.start_timer(
		"juggle",
		JUGGLE_DURATION_TICKS
	)

	await ball.tick_timer_component.timer_finished

	change_state(State.FREE)


func physics_tick() -> void:
	var player_position := player.get_logical_position()
	var player_velocity := player.get_horizontal_velocity()
	var facing_direction := player.get_facing_direction()

	# --------------------------------------------------------------------------
	# X 目标位置
	#
	# 颠球时足球目标位于角色面朝方向前方 8 像素。
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
	# 每个逻辑 Tick 重新读取角色当前 X 速度，
	# 然后根据足球与目标位置的关系修正 ±0.1875。
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
	# Y
	#
	# 与其他角色控球状态相同：
	#
	#     Ball Y = Player Y + 1
	# --------------------------------------------------------------------------

	ball.ball_horizontal_movement.set_y_position(
		player_position.y
		+ Ball.PLAYER_CONTROL_Y_OFFSET
	)


func exit() -> void:
	player = null
