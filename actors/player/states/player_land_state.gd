extends PlayerState

func enter(_data) -> void:
	step_anim.play(default_anim)
	pass

func logic_tick() -> void:
	h_move.decelerate_xy(x_decel_rate)
	if step_anim.is_finished():
		request_state(Types.PlayerStateType.IDLE)
		return
func exit() -> void:
	
	pass
