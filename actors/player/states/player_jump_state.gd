extends PlayerState


func enter(_data):
	anim.play(anim_name)
	if not player.player_z_movement.is_in_air:
		player.player_z_movement.jump(4)
		player.player_horizontal_movement.halve_y_velocity()
	await player.player_z_movement.landed
	request_state(State.LAND)
func exit():
	pass
func logic_tick() -> void:
	player.player_horizontal_movement.apply_air_steering(player.input_component.move_dir)
	pass




func handle_intent(intent: int) -> void:
	match intent:
		PlayerIntentResolver.Intent.KICK:
			if _is_reverse_direction_pressed():
				request_state(State.BICYCLE_KICK)
			else:
				player.player_z_movement.jump(4)
				request_state(State.KICK)

		PlayerIntentResolver.Intent.PASS:
			if player.ball_possession == Types.BallPossession.MYSELF:
				request_state(State.PASS)
		PlayerIntentResolver.Intent.TACKLE:
			request_state(State.AIR_KICK)


func _is_reverse_direction_pressed() -> bool:
	var move_dir := player.input_component.move_dir
	var facing_dir := player.facing_direction

	return (
		move_dir.x != 0.0
		and signf(move_dir.x) == -signf(facing_dir.x)
	)
