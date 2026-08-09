extends PlayerState


func enter():
	anim.play(anim_name)
	#player.step_animation_component.play(anim_name)
	player.start_jump()
	await player.z_axis_component.landed
	change_state(State.LAND)
func exit():
	
	pass
func physics_tick() -> void:
	var accel_step := player.DIAGONAL_ACCEL_STEP if player.is_diagonal_dir(player.input_component.move_dir) else player.CARDINAL_ACCEL_STEP
	player.speed_vector += accel_step * player.input_component.move_dir
	#print(accel_step)
	pass

func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	pass
	
