extends PlayerState

func enter(_data):
	#player.fc_logic_clock.pause()
	player.player_horizontal_movement.set_horizontal_velocity(4*player.facing_direction)
	player.player_z_movement.jump(3)
	step_anim.play(default_anim)
	await player.player_z_movement.landed
	request_state(Types.PlayerStateType.CRAWL)
	pass

func exit() -> void:
	player.close_ball_action_window()
	player.close_player_contact_window()
	pass


func logic_tick() -> void:
	player.player_horizontal_movement.apply_air_steering(player.input_component.input_direction)
	pass
