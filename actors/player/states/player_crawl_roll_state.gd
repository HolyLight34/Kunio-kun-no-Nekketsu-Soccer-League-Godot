extends PlayerState

func enter(_data) -> void:
	#player.fc_logic_clock.pause()
	step_anim.play(default_anim)
	player.player_horizontal_movement.set_horizontal_velocity(
		Vector2(0,3*player.input_component.input_direction.y)
	)
	

func exit() -> void:
	pass


func logic_tick() -> void:
	if step_anim.is_finished():
		if player.input_component.input_direction.y != 0:
			player.player_horizontal_movement.set_horizontal_velocity(
		Vector2(0,3*player.input_component.input_direction.y)
	)
			step_anim.play(default_anim)
			return
		request_state(Types.PlayerStateType.CRAWL)
		
