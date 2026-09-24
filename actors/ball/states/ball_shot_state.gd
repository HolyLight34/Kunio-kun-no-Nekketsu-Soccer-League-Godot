extends BallState
var control_input_provider: Callable
func enter(data) -> void:
	control_input_provider = data
	anim.play(anim_name)
	_prepare_hit_box(Types.AttackType.BALL_HIT,Vector2.RIGHT,5,2,4)
	ball.ball_z_movement.pause_z_motion()
	ball.tick_timer_component.start_timer(
		"shot",
		18
	)
	await ball.tick_timer_component.timer_finished
	change_state(State.FREE)
func physics_tick() -> void:
	ball.ball_horizontal_movement.apply_air_steering(control_input_provider.call())
	pass
func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	pass
