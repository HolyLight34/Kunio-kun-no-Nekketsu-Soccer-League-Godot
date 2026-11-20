extends PlayerState

func enter(_data) -> void:
	anim.play(default_anim)
	player.player_z_movement.jump(1.5)
	await player.player_z_movement.landed
	request_state(Types.PlayerStateType.LAND)
func exit() -> void:
	player.close_player_contact_window()
	pass



func logic_tick() -> void:
	pass
