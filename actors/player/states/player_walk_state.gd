extends PlayerState

func enter(_data) -> void:
	play_anim(default_anim)
	pass


func exit() -> void:
	pass

func logic_tick() -> void:
	player.player_horizontal_movement.set_move_velocity(2.375,player.input_component.input_direction)
	pass
