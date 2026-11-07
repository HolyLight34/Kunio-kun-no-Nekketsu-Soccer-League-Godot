extends PlayerState

func enter(_data) -> void:
	player.intent_a = PlayerIntentResolver.Intent.IDLE
	anim.play(anim_name)
func exit() -> void:
	pass

func logic_tick() -> void:
	player.player_horizontal_movement.decelerate_x_and_stop_y(x_decel_rate)

func handle_intent(intent: int) -> void:                                                               
	match intent:
		PlayerIntentResolver.Intent.RUN:
			request_state(State.RUN)
		PlayerIntentResolver.Intent.WALK:
			request_state(State.WALK)
		PlayerIntentResolver.Intent.KICK:
			#print("踢球",Engine.get_physics_frames())
			request_state(State.KICK)
		PlayerIntentResolver.Intent.PASS:
			request_state(State.PASS)
		PlayerIntentResolver.Intent.JUMP:
			if player.ball_possession == Types.BallPossession.MYSELF:
				request_state(State.STATIONARY_FLICK)
			else :
				request_state(State.JUMP)
		PlayerIntentResolver.Intent.ELBOW_STRIKE:
			request_state(State.ELBOW_STRIKE)
		PlayerIntentResolver.Intent.TACKLE:
			request_state(State.TACKLE)
