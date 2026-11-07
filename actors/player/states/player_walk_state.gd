extends PlayerState

func enter(_data) -> void:
	anim.play(anim_name)
	pass


func exit() -> void:
	pass

func logic_tick() -> void:
	player.player_horizontal_movement.set_move_velocity(2.375,player.input_component.move_dir)
	pass
func handle_intent(intent: int) -> void:
	match intent:
		PlayerIntentResolver.Intent.IDLE:
			request_state(State.IDLE)
		PlayerIntentResolver.Intent.JUMP:
			if player.ball_possession == Types.BallPossession.MYSELF:
				if player.input_component.move_dir == Vector2.LEFT or player.input_component.move_dir == Vector2.RIGHT:
					request_state(State.MOVING_FLICK)
					return
			request_state(State.JUMP)
		PlayerIntentResolver.Intent.RUN:
			request_state(State.RUN)
		PlayerIntentResolver.Intent.PASS:
			request_state(State.PASS)
		PlayerIntentResolver.Intent.KICK:
			if player.input_component.move_dir.x != 0:
				request_state(State.DIVINGHEADER)
			request_state(State.KICK)	
	pass
