extends BallState

func enter(_data) -> void:
	print("我是shot")
	ball.pickup_area.set_deferred(
		"monitorable",
		false
	)
	ball.ball_horizontal_component.set_horizontal_velocity(
		Vector2(8.0, 0.0)
	)
	# 固定在 Z = 8。
	ball.ball_z_movement.set_z_height(8)
	# 不产生垂直位移。
	ball.ball_z_movement.launch(0.0)
	# 禁用重力，因此不会往下掉。
	ball.ball_z_movement.gravity_enabled = false
	ball.tick_timer_component.start_timer(
		"shot",
		18
	)
	await ball.tick_timer_component.timer_finished
	change_state(State.FREE)

func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	pass
