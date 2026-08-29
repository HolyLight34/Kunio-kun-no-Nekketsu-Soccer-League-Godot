extends BallState

func enter() -> void:
	ball.pickup_area.set_deferred("monitorable", false)
	ball.tick_timer_component.start_timer("shoot",18)
	ball.ball_horizontal_component.set_horizontal_velocity(Vector2(8,0))
	ball.ball_z_movement.set_z_height(8)
	ball.ball_z_movement.grarty_entry = false
	await ball.tick_timer_component.timer_finished
	#ball.speed_vector = Vector2(7.25,0)
	#await ball.ball_z_movement.finshed
	change_state(State.FREE)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	pass
