extends PlayerState

func enter(_data) -> void:
	anim.play(anim_name)
	print("你好")
	await player.step_animation_component.animation_finished
	change_state(State.RUN)
	pass


func exit() -> void:
	
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(_intent: int, _delta: float) -> void:

	pass
