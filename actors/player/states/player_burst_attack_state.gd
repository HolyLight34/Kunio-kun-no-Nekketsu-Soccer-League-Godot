extends PlayerState
var dir: Vector2
func enter(_data) -> void:
	dir = player.input_component.move_dir
	if player.input_component.move_dir != Vector2.ZERO:
		player.player_horizontal_movement.set_move_velocity(6,dir)
	else :
		player.player_horizontal_movement.set_move_velocity(6,player.facing_direction)
	
	player.player_z_movement.jump(2)
	anim.play(anim_name)
	await player.player_z_movement.descending
	if player.input_component.move_dir != Vector2.ZERO:
		player.player_horizontal_movement.set_move_velocity(3,dir)
	else :
		player.player_horizontal_movement.set_move_velocity(6,player.facing_direction)
	await player.player_z_movement.landed
	request_state(State.LAND)
	pass


func exit() -> void:
	player.close_player_contact_window()
	pass
