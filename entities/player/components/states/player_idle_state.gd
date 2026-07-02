extends PlayerState


func enter(_params: Dictionary = {}) -> void:
	player.target_velocity = Vector2.ZERO
	print("我运行了")
	player.vh.play_anim("idle")
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
		IntentComponent.Intent.ELBOW_DIVE:
			change_state(State.ELBOW_DIVE)


func physics_process(_delta: float) -> void:
	pass
