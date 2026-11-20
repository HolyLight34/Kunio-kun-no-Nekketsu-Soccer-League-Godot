extends PlayerState

func enter(_data) -> void:
	anim.play(default_anim)
	player.player_horizontal_movement.set_horizontal_velocity(
		Vector2(0,3*player.input_component.input_direction.y)
	)
	await player.step_animation_component.animation_finished
	request_state(Types.PlayerStateType.CRAWL)
	pass

func exit() -> void:
	pass


func logic_tick() -> void:
	
		
	pass
		
