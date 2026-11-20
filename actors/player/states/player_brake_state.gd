extends PlayerState


func enter(_data):
	play_anim(default_anim)
	pass
func logic_tick() -> void:
	h_move.decelerate_x_and_stop_y(x_decel_rate)
	if h_move.horizontal_velocity_raw == Vector2i.ZERO:
		request_state(Types.PlayerStateType.IDLE)
func exit() -> void:
	pass
