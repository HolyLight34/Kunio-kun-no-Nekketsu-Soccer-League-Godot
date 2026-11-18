extends PlayerState

func enter(_data) -> void:
	anim.play(anim_name)
	await anim.animation_finished
	request_state(Types.PlayerStateType.IDLE)

func exit() -> void:
	player.close_player_contact_window()
	pass
