extends PlayerState

func enter(_data) -> void:
	player.prepare_ball_hit()
	player.ball_receiver_area.disable()
	anim.play(anim_name)
	player.player_horizontal_movement.set_horizontal_velocity(
		Vector2(0,3*player.input_component.move_dir.y)
	)
	await player.step_animation_component.animation_finished
	change_state(State.CRAWL)
	pass

func exit() -> void:
	pass


func physics_tick() -> void:
	pass
		
