extends PlayerState

func enter(_data) -> void:
	player.carried_ball.receive_stationary_flick()
	anim.play(default_anim)
	await player.step_animation_component.animation_finished
	request_state(Types.PlayerStateType.IDLE)
	pass



func exit() -> void:
	pass
