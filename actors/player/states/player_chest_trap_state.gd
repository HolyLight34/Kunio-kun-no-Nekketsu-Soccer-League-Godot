extends PlayerState

func enter(_data) -> void:
	player.player_horizontal_movement.stop_immediately()
	var dz_int = player.ball.get_z_height_integer() - player.get_z_height_integer() 
	if dz_int < 0 or dz_int >= 16:
		anim.play("chest_trap_a")
	else :
		anim.play("chest_trap_b")
	pass


func exit() -> void:
	pass

func physics_tick() -> void:
	if player.ball.is_ground_carry():
		change_state(State.IDLE)
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	pass
