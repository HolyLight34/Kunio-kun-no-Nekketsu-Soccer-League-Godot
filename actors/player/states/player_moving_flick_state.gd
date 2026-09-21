extends PlayerState
var flick_executed: bool = false

func enter(_data) -> void:
	flick_executed = false
	player.ball_interaction_detector.disable()
	player.player_horizontal_movement.stop_immediately()
	anim.play(anim_name)
	await player.step_animation_component.animation_finished
	change_state(State.IDLE)
	pass

func on_moving_flick_contact() -> void:
	if flick_executed:
		return

	flick_executed = true
	var ball := player.ball
	if ball == null:
		return
	ball.receive_moving_flick(player)
func exit() -> void:
	player.ball_interaction_detector.enable()
	pass


func process(_delta: float) -> void:
	pass


func handle_intent(intent: int, _delta: float) -> void:
	pass


func physics_process(_delta: float) -> void:
	pass
