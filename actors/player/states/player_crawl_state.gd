extends PlayerState
func enter(_data) -> void:
	#player.fc_logic_clock.pause()
	step_anim.play(default_anim)
	

func exit() -> void:
	pass


func logic_tick() -> void:
	player.player_horizontal_movement.decelerate_x_and_stop_y(x_decel_rate)
	if player.input_component.input_direction != Vector2.ZERO:
		if player.input_component.input_direction.x != 0:
			request_state(Types.PlayerStateType.CRAWL_HORIZONTAL)
		else :
			request_state(Types.PlayerStateType.CRAWL_ROLL)
		return
	if step_anim.is_finished():
		request_state(Types.PlayerStateType.LAND)
		

func on_exit_crawl() -> void:
	if player.input_component.move_dir.x == 0:
		request_state(Types.PlayerStateType.LAND)
	pass

func on_set_move_velocity() -> void:
	player.player_horizontal_movement.set_move_velocity(4,player.input_component.move_dir)
	pass
