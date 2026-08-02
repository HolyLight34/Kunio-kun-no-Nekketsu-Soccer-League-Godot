extends PlayerState

func enter() -> void:
	player.target_velocity = Vector2.ZERO
	player.action_driver_component.execute_action(action_data)
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
