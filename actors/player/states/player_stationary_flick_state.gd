extends PlayerState

func enter(_data) -> void:
	player.player_horizontal_movement.stop_immediately()
	player.ball.receive_stationary_flick()
	anim.play(anim_name)
	await player.step_animation_component.animation_finished
	request_state(State.IDLE)
	pass



func exit() -> void:
	pass
