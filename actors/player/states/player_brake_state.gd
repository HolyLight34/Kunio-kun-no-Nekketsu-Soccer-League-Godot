extends PlayerState


func enter(_data):
	anim.play(anim_name)
	await anim.animation_finished
	request_state(State.IDLE)
	pass
func logic_tick() -> void:
	player.player_horizontal_movement.decelerate_x_and_stop_y(x_decel_rate)
func exit() -> void:
	pass
