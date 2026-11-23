extends PlayerState

func enter(data: KickData) -> void:
	h_move.stop_immediately()
	if player.is_in_air():
		step_anim.play(&"jump", 2)
		z_move.jump(4)
		return

	_play_kick_anim()


#func on_animation_finished(anim_name: StringName) -> void:
	#if anim_name == &"jump":
		#_play_kick_anim()
		#return
#
	#var next_state := Types.PlayerStateType.JUMP if player.is_in_air() else Types.PlayerStateType.IDLE
	#request_state(next_state)


func _play_kick_anim() -> void:
	var kick_anim := &"kick_b" if player.carried_ball != null else &"kick_a"
	step_anim.play(kick_anim)
	
func logic_tick() -> void:
	if not step_anim.is_finished():
		return
	if step_anim.current_anim == &"jump":
		_play_kick_anim()
		return
	var next_state := Types.PlayerStateType.JUMP if player.is_in_air() else Types.PlayerStateType.IDLE
	request_state(next_state)
func _create_kick_data() -> KickData:
	var data := KickData.new()
	data.direction = player.facing_direction
	data.endurance = player.endurance

	return data
func _on_kick_with_ball() -> void:
	player.carried_ball.resolve_kick(_create_kick_data())
	pass
func exit() -> void:
	player.close_ball_action_window()
	pass
