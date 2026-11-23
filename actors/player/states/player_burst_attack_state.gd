extends PlayerState
var dir: Vector2
func enter(_data) -> void:
	player.fc_logic_clock.pause()
	dir = player.input_component.input_direction
	if player.input_component.input_direction != Vector2.ZERO:
		player.player_horizontal_movement.set_move_velocity(6,dir)
	else :
		player.player_horizontal_movement.set_move_velocity(6,player.facing_direction)
	
	player.player_z_movement.jump(2)
	step_anim.play(default_anim)
	await player.player_z_movement.descending
	if player.input_component.input_direction != Vector2.ZERO:
		player.player_horizontal_movement.set_move_velocity(3,dir)
	else :
		player.player_horizontal_movement.set_move_velocity(6,player.facing_direction)
	await player.player_z_movement.landed
	request_state(Types.PlayerStateType.LAND)
	pass


func exit() -> void:
	player.close_player_contact_window()
	pass
