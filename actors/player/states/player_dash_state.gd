extends PlayerState

func enter(_data) -> void:
	#player.fc_logic_clock.pause()
	#if player.input_component.input_direction.x != 0 and player.input_component.input_direction.y == 0:
		#player.set_facing_direction(player.input_component.input_direction)
	step_anim.play(default_anim)

func logic_tick() -> void:
	h_move.set_move_velocity(
		5,
		Vector2(player.facing_direction.x,player.input_component.input_direction.y
		).sign())
	if step_anim.is_finished():
		request_state(Types.PlayerStateType.RUN)

func exit() -> void:
	
	pass
