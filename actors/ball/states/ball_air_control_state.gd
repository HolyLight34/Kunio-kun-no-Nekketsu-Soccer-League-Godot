extends BallState

var player: Player


func enter(_data) -> void:
	player = ball.carrier
	ball.ball_z_movement.launch(
		player.get_z_velocity() + 0.5
	)
	
	print(player.get_z_velocity(),ball.ball_z_movement.get_z_velocity())
	await ball.ball_z_movement.landed
	change_state(State.GROUND_CARRY)


func physics_tick() -> void:
	var anchor_position := player.get_ball_anchor_position()

	var target_x := FixedPoint.to_integer(anchor_position.x)
	var ball_x_int := FixedPoint.to_integer(
		ball.get_logical_position().x
	)

	var player_velocity := player.get_horizontal_velocity()

	# X：继承角色当前速度，并额外向 Anchor 修正 0.5
	var x_velocity := player_velocity.x

	if ball_x_int < target_x:
		x_velocity += 0.5
	elif ball_x_int > target_x:
		x_velocity -= 0.5

	# Y：直接同步 BallAnchor.y
	# X：按照上面计算出的速度继续积分
	ball.ball_horizontal_movement.set_horizontal_velocity(
		Vector2(x_velocity, 0.0)
	)

	ball.ball_horizontal_movement.set_y_position(anchor_position.y)


func exit() -> void:
	player = null
