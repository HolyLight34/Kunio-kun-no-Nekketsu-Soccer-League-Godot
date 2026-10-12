extends PlayerState


func enter(_data):
	player.prepare_strike_hit(Types.AttackType.ELBOW,2)
	player.player_horizontal_movement.set_horizontal_velocity(4*player.facing_direction)
	player.player_z_movement.jump(3)
	anim.play(anim_name)
	await player.player_z_movement.landed
	change_state(State.CRAWL)
	pass

func exit() -> void:
	pass


func physics_tick() -> void:
	player.player_horizontal_movement.apply_air_steering(player.input_component.move_dir)
	pass
