extends PlayerState

func enter(_params: Dictionary = {}) -> void:
	player.step_animation_component.play(anim_name)
	await player.step_animation_component.animation_finished
	change_state(State.IDLE)
	pass


func exit() -> void:
	
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	pass


func handle_intent(intent: int, _delta: float) -> void:
	#match intent:
		#IntentComponent.Intent.IDLE:
			#change_state(State.IDLE)
	pass
