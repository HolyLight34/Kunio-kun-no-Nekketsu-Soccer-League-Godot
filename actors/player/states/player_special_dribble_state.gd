extends PlayerState
var dir: Vector2
func enter(_data) -> void:
	dir = player.facing_direction + player.input_component.move_dir
	player.player_horizontal_movement.set_move_velocity(
		4,dir
	)
	
	print("当前速度：",player.player_horizontal_movement.get_horizontal_velocity())
	if dir.y < 0:
		anim.play(anim_name)
	else :
		anim.play("special_dribble2")
	await anim.animation_finished
	change_state(State.RUN)
	pass
func _on_set_little_velocity() -> void:
	player.player_horizontal_movement.stop_immediately()
	print("当前速度：",player.player_horizontal_movement.get_horizontal_velocity())
	pass
func _on_set_velocity() -> void:
	player.player_horizontal_movement.set_move_velocity(
		16,dir
	)
	print("当前速度：",player.player_horizontal_movement.get_horizontal_velocity())
	pass
func exit() -> void:
	player.close_player_contact_window()
	pass





func handle_intent(_intent: int, _delta: float) -> void:
	
	pass
