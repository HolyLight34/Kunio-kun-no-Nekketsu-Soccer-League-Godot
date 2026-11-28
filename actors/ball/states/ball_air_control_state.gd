extends BallState


const TARGET_X_OFFSET := 10.0
const X_CORRECTION_SPEED := 0.5


var player: Player


func enter(_data) -> void:
	player = ball.carrier
	if player == null:
		return

	ball.ball_z_movement.launch(
		player.get_z_velocity() + 0.5
	)

	# 进入当帧立刻把 XY 速度和同步对齐，绝不残留旧速度
	_sync_horizontal_to_player()


func logic_tick() -> void:
	if player == null:
		request_state(State.FREE)
		return

	var player_z := player.get_z_height_integer()
	if ball.get_z_height_integer() <= player_z:
		request_state(State.GROUND_CARRY)
		return

	_sync_horizontal_to_player()


func exit() -> void:
	player = null


## 纯对齐函数：根据角色当前位置和速度，设置球的 XY 修正速度与同步。
func _sync_horizontal_to_player() -> void:
	var player_position := player.get_horizontal_position_integer()
	var player_velocity := player.get_horizontal_velocity()
	var facing_direction := player.get_facing_direction()

	var target_x := player_position.x + facing_direction.x * TARGET_X_OFFSET
	var ball_x := ball.get_horizontal_position_integer().x

	var x_velocity := player_velocity.x
	if ball_x < target_x:
		x_velocity += X_CORRECTION_SPEED
	elif ball_x > target_x:
		x_velocity -= X_CORRECTION_SPEED

	ball.ball_horizontal_movement.set_horizontal_velocity(
		Vector2(x_velocity, player_velocity.y)
	)
	ball.ball_horizontal_movement.sync_position(player_position, false)
