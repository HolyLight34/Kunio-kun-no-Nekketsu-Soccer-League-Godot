extends PlayerState

func enter(_data) -> void:
	h_move.stop_immediately()
	step_anim.play(default_anim)
	
	pass
func logic_tick() -> void:
	if step_anim.is_finished():
		request_state(Types.PlayerStateType.IDLE)
func exit() -> void:
	player.close_ball_action_window()
	pass
