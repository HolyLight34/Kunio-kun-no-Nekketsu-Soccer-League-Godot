extends BallState

func enter() -> void:
	ball.pickup_area.set_deferred("monitorable", false)
	#ball.z_axis_component.set_flat_flight(8,18)
	ball.speed_vector = Vector2(8,0)
	await ball.ball_z_movement.landed
	ball.speed_vector = Vector2(7.25,0)
	await ball.ball_z_movement.finshed
	change_state(State.FREE)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	pass
