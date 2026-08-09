extends PlayerState

func enter() -> void:
	player.speed_vector = Vector2.ZERO
	anim.play(anim_name)
	#player.step_animation_component.play(anim_name)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass


func handle_intent(intent: int, _delta: float) -> void:                                                               
	match intent:
		IntentComponent.Intent.RUN:
			change_state(State.RUN)
		IntentComponent.Intent.WALK:
			change_state(State.WALK)
		IntentComponent.Intent.KICK:
			change_state(State.ACTION_B)	
		IntentComponent.Intent.SEND_PASS:
			change_state(State.ACTION_A)
		IntentComponent.Intent.JUMP:
			change_state(State.JUMP)


func physics_process(_delta: float) -> void:
	pass
