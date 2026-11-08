extends PlayerState

func enter(_data) -> void:
	player.fc_logic_clock.pause()
	player.player_horizontal_movement.stop_immediately()
	player.player_z_movement.jump(4)
	if player.carried_ball:
		anim.play("bicycle_kick_with_ball")
	else :
		anim.play("bicycle_kick")
	
	await anim.animation_finished
	if player.player_z_movement.is_in_air:
		request_state(State.JUMP)
	pass

## 动画事件：触发倒钩挑球。
func on_bicycle_kick_flick() -> void:
	if player.carried_ball:
		player.carried_ball.receive_bicycle_kick_flick()
func on_kick_shoot() -> void:
	
	var data := KickData.new()
	data.direction = player.facing_direction
	data.endurance = player.endurance
	player.carried_ball.resolve_kick(data)
	pass
func exit() -> void:
	
	pass
