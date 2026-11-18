extends PlayerState

func enter(_data) -> void:
	if player.input_component.input_direction != Vector2.ZERO:
		player.set_facing_direction(player.input_component.input_direction)
	anim.play(anim_name)

func logic_tick() -> void:
	player.player_horizontal_movement.set_move_velocity(
		3,
		Vector2(player.facing_direction.x,player.input_component.input_direction.y
		).sign())

func exit() -> void:
	
	pass
