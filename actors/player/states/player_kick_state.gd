extends PlayerState


func enter(_data):
	player.prepare_kick_hit(KickData.KickType.NORMAL)
	player.ball_receiver_area.disable()
	player.player_horizontal_movement.stop_immediately()
	anim.play(anim_name)
	await anim.animation_finished
	if player.player_z_movement.is_in_air:
		change_state(State.JUMP)
	change_state(State.IDLE)
	pass

func exit() -> void:
	pass

func physics_tick() -> void:
	pass
func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass
