extends PlayerState


func enter():
	player.step_animation_component.play(anim_name)
	player.start_jump()
	await player.z_axis_component.landed
	change_state(State.LAND)
func exit():
	
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	pass
	
