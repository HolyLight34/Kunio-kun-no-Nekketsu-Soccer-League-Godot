extends PlayerState

func enter(_data) -> void:
	player.step_animation_component.play(anim_name)
	await anim.animation_finished
	request_state(Types.PlayerStateType.IDLE)
	pass

func logic_tick() -> void:
	player.player_horizontal_movement.decelerate_xy(x_decel_rate)
	pass
func exit() -> void:
	
	pass
