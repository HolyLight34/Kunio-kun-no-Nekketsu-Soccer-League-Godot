extends BallState
var kicker: Player
func enter(data: HitInfo) -> void:
	kicker = ball.current_kicker
	anim.play(anim_name)
	data.attack_type = Types.AttackType.BALL_HIT
	ball.hit_box.hit_info = data
	var hit_info: HitInfo = ball.hit_box.hit_info
	ball.ball_horizontal_movement.set_horizontal_velocity(
		hit_info.attack_direction*8
	)
	# 固定在 Z = 8。
	ball.ball_z_movement.set_z_height(8)
	# 不产生垂直位移。
	ball.ball_z_movement.launch(0.0)
	# 禁用重力，因此不会往下掉。
	ball.ball_z_movement.gravity_enabled = false
	ball.tick_timer_component.start_timer(
		"shot",
		18
	)
	await ball.tick_timer_component.timer_finished
	change_state(State.FREE)
func physics_tick() -> void:
	ball.ball_horizontal_movement.apply_air_steering(kicker.input_component.move_dir)
func exit() -> void:
	ball.current_kicker = null
	pass


func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	pass
