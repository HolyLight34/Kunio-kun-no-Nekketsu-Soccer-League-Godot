extends PlayerState

func enter(_data) -> void:
	player.player_horizontal_movement.stop_immediately()
	var dz_int = player.ball.get_z_height_integer() - player.get_z_height_integer() 
	if dz_int < 0 or dz_int >= 16:
		anim.play("juggle_a")
	else :
		anim.play("juggle_b")
	await player.step_animation_component.animation_finished
	request_state(State.RUN)
	pass


func exit() -> void:
	
	pass
