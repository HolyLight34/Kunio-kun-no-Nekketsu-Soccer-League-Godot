extends PlayerState


func enter(_data):
	anim.play(anim_name)
	pass
func logic_tick() -> void:
	player.player_horizontal_movement.decelerate_x_and_stop_y(x_decel_rate)
	if player.player_horizontal_movement.horizontal_velocity_raw == Vector2i.ZERO:
		request_state(Types.PlayerStateType.IDLE)
func exit() -> void:
	pass
