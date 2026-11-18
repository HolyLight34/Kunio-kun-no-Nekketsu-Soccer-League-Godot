extends PlayerState

func enter(_data) -> void:
	anim.play(anim_name)
	await player.step_animation_component.animation_finished
	if player.input_component.input_direction != Vector2.ZERO:
		if player.input_component.input_direction.x != 0:
			request_state(Types.PlayerStateType.CRAWL_HORIZONTAL)
		else :
			request_state(Types.PlayerStateType.CRAWL_ROLL)
	else :
		request_state(Types.PlayerStateType.LAND)

func exit() -> void:
	pass


func logic_tick() -> void:
	player.player_horizontal_movement.decelerate_x_and_stop_y(x_decel_rate)
		

func on_exit_crawl() -> void:
	if player.input_component.move_dir.x == 0:
		request_state(Types.PlayerStateType.LAND)
	pass

func on_set_move_velocity() -> void:
	player.player_horizontal_movement.set_move_velocity(4,player.input_component.move_dir)
	pass
