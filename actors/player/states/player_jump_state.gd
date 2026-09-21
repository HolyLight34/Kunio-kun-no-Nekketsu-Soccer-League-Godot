extends PlayerState


func enter(_data):
	anim.play(anim_name)
	if not player.player_z_movement.is_in_air:
		player.player_z_movement.apply_vertical_velocity(4)
		player.player_horizontal_movement.halve_y_velocity()
	await player.player_z_movement.landed
	change_state(State.LAND)
func exit():
	pass
func physics_tick() -> void:
	player.player_horizontal_movement.apply_air_steering(player.input_component.move_dir)
	pass

func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(intent: int, _delta: float) -> void:
	match intent:
		PlayerIntentResolver.Intent.KICK:
			player.player_z_movement.apply_vertical_velocity(4)
			change_state(State.KICK)	
	pass
	
