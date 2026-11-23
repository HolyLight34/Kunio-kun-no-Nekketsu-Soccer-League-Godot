extends PlayerState


func enter(_data) -> void:
	step_anim.play(default_anim)
	if player.input_component.input_direction == Vector2.ZERO:
		player.player_horizontal_movement.set_horizontal_velocity(5*player.facing_direction)
	else :
		player.player_horizontal_movement.set_horizontal_velocity(5*player.input_component.input_direction)
	
	pass
func logic_tick() -> void:
	player.player_horizontal_movement.decelerate_xy(x_decel_rate)
	if step_anim.is_finished():
		request_state(Types.PlayerStateType.LAND)
	pass
func exit() -> void:
	player.close_ball_action_window()
	player.close_player_contact_window()
	pass
