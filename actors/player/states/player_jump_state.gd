extends PlayerState


func enter(_data):
	play_anim(default_anim)
	if not player.is_in_air():
		z_move.jump(4)
		h_move.halve_y_velocity()
	await z_move.landed
	request_state(Types.PlayerStateType.LAND)
func exit():
	pass
func logic_tick() -> void:
	h_move.apply_air_steering(player.input_component.input_direction)
	pass



func _is_reverse_direction_pressed() -> bool:
	var move_dir := player.input_component.input_direction
	var facing_dir := player.facing_direction

	return (
		move_dir.x != 0.0
		and signf(move_dir.x) == -signf(facing_dir.x)
	)
