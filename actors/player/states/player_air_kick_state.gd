extends PlayerState

func enter(_data) -> void:
	anim.play(anim_name)
	player.player_z_movement.jump(1.5)
	await player.player_z_movement.landed
	change_state(State.LAND)
func exit() -> void:
	player.close_player_contact_window()
	pass



func physics_tick() -> void:
	pass

func handle_intent(intent: int, _delta: float) -> void:                                                               
	
		pass
