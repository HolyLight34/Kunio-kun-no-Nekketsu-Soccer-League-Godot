extends PlayerState

func enter(_data) -> void:
	player.player_horizontal_movement.stop_immediately()
	anim.play(anim_name)
	await anim.animation_finished
	request_state(State.IDLE)
	pass

func exit() -> void:
	player.close_ball_action_window()
	pass
