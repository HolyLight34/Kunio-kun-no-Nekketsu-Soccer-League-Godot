extends PlayerState

func enter(_data) -> void:
	player.ball_receiver_area.disable()
	player.prepare_pass_hit()
	anim.play(anim_name)
	await anim.animation_finished
	change_state(State.IDLE)
	pass

func exit() -> void:
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	
	pass
