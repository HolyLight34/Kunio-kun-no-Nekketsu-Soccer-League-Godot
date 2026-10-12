extends PlayerState

func enter(_data) -> void:
	anim.play(anim_name)
	pass

func exit() -> void:
	pass


func physics_tick() -> void:
	player.player_horizontal_movement.decelerate_x_and_stop_y(x_decel_rate)
	if player.player_horizontal_movement.get_horizontal_velocity() == Vector2.ZERO:
		change_state(State.LAND)
	pass

func handle_intent(_intent: int, _delta: float) -> void:
	
	pass
