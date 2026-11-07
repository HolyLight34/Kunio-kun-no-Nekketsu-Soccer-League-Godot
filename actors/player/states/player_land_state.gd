extends PlayerState

func enter(_data) -> void:
	player.step_animation_component.play(anim_name)
	await anim.animation_finished
	request_state(State.IDLE)
	pass

func logic_tick() -> void:
	player.player_horizontal_movement.decelerate_xy(x_decel_rate)
	pass
func exit() -> void:
	
	pass


func handle_intent(intent: int) -> void:
	match intent:
		PlayerIntentResolver.Intent.ELBOW_STRIKE:
			request_state(State.BURST_ATTACK)
	pass
