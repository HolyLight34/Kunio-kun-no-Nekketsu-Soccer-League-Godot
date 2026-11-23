extends PlayerState
var is_decelerate: bool = true
func enter(_data) -> void:
	#player.fc_logic_clock.pause()
	step_anim.play(default_anim)
	

func exit() -> void:
	pass


func logic_tick() -> void:
	if is_decelerate:
		h_move.decelerate_x_and_stop_y(x_decel_rate)
	if step_anim.is_finished():
		if player.input_component.input_direction.x != 0:
			step_anim.play(default_anim)
			return
		request_state(Types.PlayerStateType.CRAWL)
		

func on_set_move_velocity() -> void:
	player.player_horizontal_movement.set_move_velocity(4,player.input_component.input_direction)
	pass
