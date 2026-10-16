extends PlayerState
var dir: Vector2
func enter(_data) -> void:
	player.prepare_strike_hit(2)
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
	change_state(State.LAND)
	pass


func exit() -> void:
	
	pass


func handle_intent(_intent: int, _delta: float) -> void:

	pass
