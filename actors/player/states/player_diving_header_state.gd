extends PlayerState


func enter(_data):
	#player.ball_receiver_area.disable()
	#player.prepare_kick_hit()
	#player.prepare_strike_hit(2)
	player.player_horizontal_movement.set_horizontal_velocity(4*player.facing_direction)
	player.player_z_movement.jump(3)
	anim.play(anim_name)
	await player.player_z_movement.landed
	change_state(State.CRAWL)
	pass

func exit() -> void:
	player.close_ball_action_window()
	player.close_player_contact_window()
	pass


func physics_tick() -> void:
	player.player_horizontal_movement.apply_air_steering(player.input_component.move_dir)
	pass
