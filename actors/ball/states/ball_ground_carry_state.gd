extends BallState


const TARGET_X_OFFSET := 12.0


func enter(_data) -> void:
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

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

	var player_position := ball.carrier.get_logical_position()
	var facing_direction := ball.carrier.get_facing_direction()

	# --------------------------------------------------------------------------
	# 计算带球目标位置
	#
	# X：
	#     角色面朝方向前方 12 像素
	#
	# Y：
	#     角色逻辑 Y + 统一控球偏移
	# --------------------------------------------------------------------------

	var target_position := Vector2(
		player_position.x
			+ facing_direction.x * TARGET_X_OFFSET,

		player_position.y
			+ Ball.PLAYER_CONTROL_Y_OFFSET
	)

	# --------------------------------------------------------------------------
	# 地面带球
	#
	# GroundCarry 不需要追赶目标位置，
	# 足球直接同步到角色当前的控球位置。
	# --------------------------------------------------------------------------

	ball.ball_horizontal_movement.set_horizontal_position(
		target_position
	)

	# --------------------------------------------------------------------------
	# 带球跳跃
	#
	# 角色处于空中时，足球 Z 高度同步角色 Z。
	# --------------------------------------------------------------------------

	if ball.carrier.is_in_air():
		ball.ball_z_movement.set_z_height(
			ball.carrier.get_z_height()
		)
	pass
	
