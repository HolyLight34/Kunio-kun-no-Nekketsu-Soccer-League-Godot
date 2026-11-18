extends PlayerState

func enter(_data) -> void:
	anim.play(anim_name)
func exit() -> void:
	pass

func logic_tick() -> void:
	player.player_horizontal_movement.decelerate_x_and_stop_y(x_decel_rate)
