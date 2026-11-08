extends PlayerState
var dir: Vector2
var init_speed: Vector2
func enter(_data) -> void:
	#player.fc_logic_clock.pause()
	dir = player.facing_direction + (-player.input_component.move_dir)
	player.player_horizontal_movement.set_move_velocity(
		4,dir
	)
	init_speed = player.player_horizontal_movement.get_horizontal_velocity()
	print("当前速度：",player.player_horizontal_movement.get_horizontal_velocity())
	if dir.y < 0:
		anim.play(anim_name)
	else :
		anim.play("special_dribble2")
	await anim.animation_finished
	request_state(State.RUN)
	pass
func _on_set_little_velocity() -> void:
	player.player_horizontal_movement.stop_immediately()
	print("当前速度：",player.player_horizontal_movement.get_horizontal_velocity())
	pass
func _on_set_velocity() -> void:
	init_speed.y = -init_speed.y
	player.player_horizontal_movement.set_horizontal_velocity(
		4*init_speed
	)
	print("当前速度：",player.player_horizontal_movement.get_horizontal_velocity())
	pass
func exit() -> void:
	player.close_player_contact_window()
	pass
