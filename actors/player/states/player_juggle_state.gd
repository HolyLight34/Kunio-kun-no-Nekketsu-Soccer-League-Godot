extends PlayerState

func enter(_data) -> void:
	#player.fc_logic_clock.pause()
	var dz_int = player.carried_ball.get_z_height_integer() - player.get_z_height_integer() 
	if dz_int < 0 or dz_int >= 16:
		step_anim.play("juggle_a")
	else :
		step_anim.play("juggle_b")
	pass

func logic_tick() -> void:
	if step_anim.is_finished():
		request_state(Types.PlayerStateType.RUN)
func exit() -> void:
	
	pass
