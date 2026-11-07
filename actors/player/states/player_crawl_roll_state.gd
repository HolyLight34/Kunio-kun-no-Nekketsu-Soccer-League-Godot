extends PlayerState

func enter(_data) -> void:
	anim.play(anim_name)
	player.player_horizontal_movement.set_horizontal_velocity(
		Vector2(0,3*player.input_component.move_dir.y)
	)
	await player.step_animation_component.animation_finished
	request_state(State.CRAWL)
	pass

func exit() -> void:
	pass


func logic_tick() -> void:
	
		
	pass
		
