extends PlayerState


func enter(_data):
	anim.play(anim_name)
	if not player.player_z_movement.is_in_air:
		player.player_z_movement.jump(4)
		player.player_horizontal_movement.halve_y_velocity()
	await player.player_z_movement.landed
	request_state(Types.PlayerStateType.LAND)
func exit():
	pass
func logic_tick() -> void:
	player.player_horizontal_movement.apply_air_steering(player.input_component.input_direction)
	pass



func _is_reverse_direction_pressed() -> bool:
	var move_dir := player.input_component.input_direction
	var facing_dir := player.facing_direction

	return (
		move_dir.x != 0.0
		and signf(move_dir.x) == -signf(facing_dir.x)
	)
