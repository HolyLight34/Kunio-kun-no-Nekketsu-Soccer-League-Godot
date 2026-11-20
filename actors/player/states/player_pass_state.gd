extends PlayerState

func enter(_data) -> void:
	h_move.stop_immediately()
	anim.play(default_anim)
	await anim.animation_finished
	request_state(Types.PlayerStateType.IDLE)
	pass

func exit() -> void:
	player.close_ball_action_window()
	pass
