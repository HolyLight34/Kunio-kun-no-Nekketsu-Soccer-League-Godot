extends PlayerState

func enter(_data) -> void:
	player.player_horizontal_movement.stop_immediately()
	player.player_z_movement.jump(4)
	if player.ball:
		anim.play("bicycle_kick_with_ball")
	else :
		anim.play("bicycle_kick")
	
	await anim.animation_finished
	if player.player_z_movement.is_in_air:
		change_state(State.JUMP)
	pass

## 动画事件：触发倒钩挑球。
func on_bicycle_kick_flick() -> void:
	player.ball.receive_bicycle_kick_flick()
func exit() -> void:
	
	pass


func handle_intent(_intent: int, _delta: float) -> void:

	pass
