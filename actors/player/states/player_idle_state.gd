extends PlayerState

func enter(_data) -> void:
	step_anim.play(default_anim)
func exit() -> void:
	pass

func logic_tick() -> void:
	h_move.decelerate_x_and_stop_y(x_decel_rate)
