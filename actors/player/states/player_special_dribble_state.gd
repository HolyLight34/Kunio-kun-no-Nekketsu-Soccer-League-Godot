extends PlayerState
var dir: Vector2
var init_speed: Vector2
func enter(_data) -> void:
	#player.fc_logic_clock.pause()
	dir = player.facing_direction + (-player.input_component.input_direction)
	player.player_horizontal_movement.set_move_velocity(
		4,dir
	)
	init_speed = player.player_horizontal_movement.get_horizontal_velocity()
	print("当前速度：",player.player_horizontal_movement.get_horizontal_velocity())
	if dir.y < 0:
		step_anim.play(&"special_dribble2")
	else :
		step_anim.play(&"special_dribble1")
	
	pass
func logic_tick() -> void:
	if step_anim.is_finished():
		request_state(Types.PlayerStateType.RUN)
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
