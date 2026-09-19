extends BallState

func enter(_data) -> void:
	ball.ball_horizontal_movement.set_horizontal_velocity(
		ball.carrier.player_horizontal_movement.get_horizontal_velocity() 
	)
	await ball.ball_z_movement.landed
	change_state(State.GRIYND_CARRY)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass
