extends BallState


const TARGET_X_OFFSET := 12


func enter(_data) -> void:
	#ball.fc_logic_clock.pause()
	# 携带期间足球 Z 不执行自身重力，高度与速度由持球角色同步。
	ball.ball_z_movement.gravity_enabled = false
	ball.ball_z_movement.z_velocity_raw = 0

	if ball.carrier != null:
		_sync_to_carrier()


func exit() -> void:
	ball.ball_horizontal_movement.clear_position_sync()
	ball.ball_z_movement.clear_z_position_sync()


func logic_tick() -> void:
	# 没有持球角色时回到自由状态。
	if ball.carrier == null:
		request_state(State.FREE)
		return

	_sync_to_carrier()


## 将球的水平/垂直位置与速度同步到当前持球角色。
func _sync_to_carrier() -> void:
	var player_position: Vector2i = ball.carrier.get_horizontal_position_integer()
	var facing_direction: Vector2 = ball.carrier.get_facing_direction()

	var target_position := Vector2i(
		player_position.x + roundi(facing_direction.x * TARGET_X_OFFSET),
		player_position.y
	)

	ball.ball_horizontal_movement.set_horizontal_velocity(ball.carrier.get_horizontal_velocity())
	ball.ball_horizontal_movement.sync_position(target_position)
	ball.ball_z_movement.set_z_velocity(ball.carrier.get_z_velocity())
	ball.ball_z_movement.sync_z_position(ball.carrier.get_z_height_integer())
