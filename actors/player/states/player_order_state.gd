extends PlayerState

func enter(_data) -> void:
	player.fc_logic_clock.pause()
	step_anim.play(default_anim)

func logic_tick() -> void:
	h_move.decelerate_x_and_stop_y(x_decel_rate)
	if step_anim.is_finished():
		request_state(Types.PlayerStateType.IDLE)

func exit() -> void:
	
	pass
