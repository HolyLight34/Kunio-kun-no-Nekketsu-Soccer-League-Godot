extends BallState

func enter(_data) -> void:
	
	pass
	


func exit() -> void:
	pass

func physics_tick() -> void:
		# --------------------------------------------------------------------------

	var player_position: Vector2i = (
		ball.carrier.get_horizontal_position_integer()
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

	var target_position := Vector2i(
		player_position.x,

		player_position.y
			+ Ball.PLAYER_CONTROL_Y_OFFSET
	)


	# --------------------------------------------------------------------------
	# 同步足球水平位置
	#
	# 携带期间足球保持在角色对应的控球位置。
	# --------------------------------------------------------------------------

	ball.ball_horizontal_movement.set_horizontal_integer_position(
		target_position
	)
	
	pass
