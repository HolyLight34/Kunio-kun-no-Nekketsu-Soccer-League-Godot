extends PlayerState

func enter() -> void:
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


func handle_intent(intent: int, _delta: float) -> void:
	
	pass
