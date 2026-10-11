
extends BallState


## FC 踢球初始化参数。
const KICK_TICK: int = 3
const INITIAL_SPEED: int = 8
const INITIAL_TICK: int = 16

## 球场左右边界（用于计算高空踢球持续时间）。
const LEFT_BOUNDARY: int = 272
const RIGHT_BOUNDARY: int = 624

## 高空踢球判定高度。
const HIGH_KICK_HEIGHT: int = 28
var is_high:bool = false

func enter(data: KickData) -> void:
	ball.ball_z_movement.gravity_disable()

	var attack_direction: Vector2 = data.direction

	# 计算足球朝球门飞行的方向。
	var goal_target: Vector2 = ball.get_goal_target_position(
		attack_direction
	)

	var shot_direction: Vector2 = FCDirectionCalculator.calculate(
		ball.get_logical_position(),
		goal_target
	)

	var power: int = 0
	var z_velocity: int = 0
	var time_tick: int = 0

	# ================================================
	# 1. 根据足球高度确定踢球参数
	# ================================================

	if not ball.is_in_air():
		# 地面踢球。
		time_tick = INITIAL_TICK - KICK_TICK
		ball.ball_z_movement.set_z_height(8)
		is_high = false

	elif FixedPoint.to_integer(ball.get_z_height()) > HIGH_KICK_HEIGHT:
		is_high = true
		# 高空踢球。
		z_velocity = 1
		power = data.endurance + 20

		time_tick = _calculate_high_kick_duration(
			attack_direction
		)

		anim.play(anim_name)

		ball.ball_z_movement.set_z_height(
			ball.get_z_height() + z_velocity * KICK_TICK
		)

	else:
		# 原代码中这一高度区间尚未实现。
		push_warning(
			"BallShotState: 中低空踢球规则尚未实现"
		)
		return

	# ================================================
	# 2. 初始化足球运动
	# ================================================

	ball.ball_z_movement.launch(z_velocity)

	ball.ball_horizontal_movement.set_horizontal_position(
		ball.get_logical_position()
		+ shot_direction * INITIAL_SPEED * KICK_TICK
	)

	ball.ball_horizontal_movement.set_horizontal_velocity(
		shot_direction * INITIAL_SPEED
	)

	# ================================================
	# 3. 初始化足球攻击判定
	# ================================================

	ball.enable_hit()

	ball.prepare_ball_attack_hit(
		attack_direction,
		power,
		5
	)

	# ================================================
	# 4. 启动持续时间
	# ================================================

	ball.ball_z_movement.start_height_hold()

	ball.tick_timer_component.start_timer(
		"shot",
		time_tick
	)
	await ball.tick_timer_component.timer_finished
	ball.ball_z_movement.gravity_enable()
	if is_high:
		await ball.ball_z_movement.landed
		ball.ball_horizontal_movement.set_horizontal_velocity(
		shot_direction * INITIAL_SPEED * 2
		)
		ball.ball_z_movement.launch(4)
	else :
		change_state(State.FREE)
	


func physics_tick() -> void:
	pass


func exit() -> void:
	ball.disable_hit()
	ball.ball_z_movement.stop_height_hold()


## 计算高空踢球的持续逻辑步数。
func _calculate_high_kick_duration(
	attack_direction: Vector2
) -> int:
	var ball_x: int = FixedPoint.to_integer(
		ball.get_logical_position().x
	)

	if attack_direction == Vector2.RIGHT:
		return (RIGHT_BOUNDARY - ball_x) / INITIAL_SPEED

	return (ball_x - LEFT_BOUNDARY) / INITIAL_SPEED
