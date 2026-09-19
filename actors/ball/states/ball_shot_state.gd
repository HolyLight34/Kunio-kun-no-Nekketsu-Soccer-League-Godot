extends BallState
var kicker: Player
func enter(data: HitInfo) -> void:
	print("飞行高度",ball.get_z_height())
	ball.ball_collision.set_deferred("disabled", true)
	kicker = ball.current_kicker
	anim.play(anim_name)
	_prepare_hit_box(Types.AttackType.BALL_HIT,Vector2.RIGHT,5,2,4)
	#ball.ball_horizontal_movement.set_horizontal_velocity(
		#data.attack_direction*data.horizontal_speed
	#)
	# 固定在 Z = 8。
	#ball.ball_z_movement.set_z_height(data.z_velocity)
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
	ball.ball_collision.set_deferred("disabled", false)
	pass


func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	pass
