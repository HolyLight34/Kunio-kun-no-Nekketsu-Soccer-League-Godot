extends PlayerState

func enter(_data) -> void:
	player.player_horizontal_movement.stop_immediately()
	#player.ball_receiver_area.disable()
	#player.prepare_pass_hit()
	anim.play(anim_name)
	await anim.animation_finished
	change_state(State.IDLE)
	pass

func exit() -> void:
	player.close_ball_action_window()
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	
	pass
