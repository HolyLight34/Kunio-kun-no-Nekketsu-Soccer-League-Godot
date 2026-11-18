extends PlayerState

func enter(_data) -> void:
	player.carried_ball.receive_stationary_flick()
	anim.play(anim_name)
	await player.step_animation_component.animation_finished
	request_state(Types.PlayerStateType.IDLE)
	pass



func exit() -> void:
	pass
