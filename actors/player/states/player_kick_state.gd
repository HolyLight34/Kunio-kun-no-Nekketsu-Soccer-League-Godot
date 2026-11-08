extends PlayerState

func enter(_data):
	player.player_horizontal_movement.stop_immediately()
	if player.carried_ball != null:
		print("你好")
		anim.play("kick_b")
	else :
		anim.play("kick_a")
	await anim.animation_finished
	if player.player_z_movement.is_in_air:
		request_state(State.JUMP)
	request_state(State.IDLE)
	pass

func exit() -> void:
	player.close_ball_action_window()
	pass

func logic_tick() -> void:
	pass
