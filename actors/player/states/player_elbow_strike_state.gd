extends PlayerState

func enter(_data) -> void:
	#player.fc_logic_clock.pause()
	step_anim.play(default_anim)
	
func logic_tick() -> void:
	if step_anim.is_finished():
		request_state(Types.PlayerStateType.IDLE)
func exit() -> void:
	player.close_player_contact_window()
	pass
