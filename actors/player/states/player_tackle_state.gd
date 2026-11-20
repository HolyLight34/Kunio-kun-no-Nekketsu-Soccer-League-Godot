extends PlayerState


func enter(_data) -> void:
	anim.play(default_anim)
	if player.input_component.input_direction == Vector2.ZERO:
		player.player_horizontal_movement.set_horizontal_velocity(5*player.facing_direction)
	else :
		player.player_horizontal_movement.set_horizontal_velocity(5*player.input_component.input_direction)
	await anim.animation_finished
	request_state(Types.PlayerStateType.LAND)
	pass
func logic_tick() -> void:
	player.player_horizontal_movement.decelerate_xy(x_decel_rate)
	pass
func exit() -> void:
	player.close_ball_action_window()
	player.close_player_contact_window()
	pass
