extends PlayerState

func enter(_data):
	player.player_horizontal_movement.stop_immediately()
	if player.carried_ball != null:
		anim.play("kick_b")
	else :
		anim.play("kick_a")
	await anim.animation_finished
	if player.player_z_movement.is_in_air:
		request_state(State.JUMP)
	request_state(State.IDLE)
	pass
func _on_kick_with_ball() -> void:
	player.carried_ball.resolve_kick(_create_kick_data())
	pass
func exit() -> void:
	player.close_ball_action_window()
	pass

func logic_tick() -> void:
	pass
func _create_kick_data() -> KickData:
	var data := KickData.new()
	data.direction = player.facing_direction
	data.endurance = player.endurance

	return data
