extends PlayerState


func enter(_params: Dictionary = {}) -> void:
	print('DKJFE')
	player.target_velocity = Vector2.ZERO
	print("我运行了")
	player.vh.play_anim("idle")
	#player.animation_player.play("idle")
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass


func handle_intent(intent: int, _delta: float) -> void:
	match intent:
		IntentComponent.Intent.RUN:
			change_state(State.DRIBBLE_RUN)
		IntentComponent.Intent.WALK:
			change_state(State.DRIBBLE_WALK)
		IntentComponent.Intent.KICK:
			change_state(State.KICK)
		


func physics_process(_delta: float) -> void:
	pass
