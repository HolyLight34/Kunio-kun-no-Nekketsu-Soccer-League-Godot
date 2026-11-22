extends PlayerState

func enter(_data) -> void:
	play_anim(default_anim)

func logic_tick() -> void:
	h_move.decelerate_x_and_stop_y(x_decel_rate)
	pass

func exit() -> void:
	
	pass
func on_animation_finished(_anim_name: StringName) -> void:
	request_state(Types.PlayerStateType.IDLE)
