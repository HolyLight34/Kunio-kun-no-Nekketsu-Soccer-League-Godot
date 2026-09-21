extends PlayerState

func enter(_data) -> void:
	anim.play(anim_name)
func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass
func physics_tick() -> void:
	player.player_horizontal_movement.decelerate_x_and_stop_y(x_decel_rate)

func handle_intent(intent: int, _delta: float) -> void:                                                               
	match intent:
		PlayerIntentResolver.Intent.RUN:
			change_state(State.RUN)
		PlayerIntentResolver.Intent.WALK:
			change_state(State.WALK)
		PlayerIntentResolver.Intent.KICK:
			change_state(State.KICK)	
		PlayerIntentResolver.Intent.PASS:
			change_state(State.PASS)
		PlayerIntentResolver.Intent.JUMP:
			if player.ball_possession == Types.BallPossession.MYSELF:
				change_state(State.STATIONARY_FLICK)
			else :
				change_state(State.JUMP)
		PlayerIntentResolver.Intent.ELBOW_STRIKE:
			change_state(State.ELBOW_STRIKE)
		PlayerIntentResolver.Intent.TACKLE:
			change_state(State.TACKLE)


func physics_process(_delta: float) -> void:
	pass
