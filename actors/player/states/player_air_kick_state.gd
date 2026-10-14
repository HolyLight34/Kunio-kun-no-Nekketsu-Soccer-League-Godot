extends PlayerState

func enter(_data) -> void:
	player.prepare_strike_hit(2)
	anim.play(anim_name)
	player.player_z_movement.jump(1.5)
	await player.player_z_movement.landed
	change_state(State.LAND)
func exit() -> void:
	pass



func physics_tick() -> void:
	pass

func handle_intent(intent: int, _delta: float) -> void:                                                               
	#match intent:
		#PlayerIntentResolver.Intent.RUN:
			#change_state(State.RUN)
		#PlayerIntentResolver.Intent.WALK:
			#change_state(State.WALK)
		#PlayerIntentResolver.Intent.KICK:
			#change_state(State.KICK)	
		#PlayerIntentResolver.Intent.PASS:
			#change_state(State.PASS)
		#PlayerIntentResolver.Intent.JUMP:
			#if player.ball_possession == Types.BallPossession.MYSELF:
				#change_state(State.STATIONARY_FLICK)
			#else :
				#change_state(State.JUMP)
		#PlayerIntentResolver.Intent.ELBOW_STRIKE:
			#change_state(State.ELBOW_STRIKE)
		#PlayerIntentResolver.Intent.TACKLE:
			#change_state(State.TACKLE)
		pass
