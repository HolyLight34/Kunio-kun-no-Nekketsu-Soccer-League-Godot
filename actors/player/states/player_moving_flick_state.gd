extends PlayerState
var flick_executed: bool = false

func enter(_data) -> void:
	flick_executed = false
	player.player_horizontal_movement.stop_immediately()
	step_anim.play(default_anim)
	pass
func logic_tick() -> void:
	if step_anim.is_finished():
		request_state(Types.PlayerStateType.IDLE)
func on_moving_flick_contact() -> void:
	if flick_executed:
		return

	flick_executed = true
	var ball := player.carried_ball
	if ball == null:
		return
	ball.receive_moving_flick(player)
func exit() -> void:
	pass
