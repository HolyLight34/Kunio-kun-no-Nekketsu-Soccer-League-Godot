extends BallState

func enter(_data) -> void:
	anim.play(default_anim)
	ball.ball_z_movement.gravity_enable()
	ball.release_from_carrier()
	if not ball.player_interaction_enabled:
		await ball.ball_z_movement.started_descending
		ball.player_interaction_enabled = true
	pass
	


func exit() -> void:
	pass

func logic_tick() -> void:
	pass
