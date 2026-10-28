extends PlayerState

func enter(_data) -> void:
	#player.ball_receiver_area.disable()
	anim.play(anim_name)
	await player.step_animation_component.animation_finished
	if player.input_component.move_dir != Vector2.ZERO:
		#player.prepare_ball_hit()
		if player.input_component.move_dir.x != 0:
			change_state(State.CRAWL_HORIZONTAL)
		else :
			change_state(State.CRAWL_ROLL)
	else :
		change_state(State.LAND)

func exit() -> void:
	pass


func physics_tick() -> void:
	player.player_horizontal_movement.decelerate_x_and_stop_y(x_decel_rate)
	#print(player.player_horizontal_movement.get_horizontal_velocity())
		

func on_exit_crawl() -> void:
	if player.input_component.move_dir.x == 0:
		change_state(State.LAND)
	pass

func on_set_move_velocity() -> void:
	player.player_horizontal_movement.set_move_velocity(4,player.input_component.move_dir)
	pass
