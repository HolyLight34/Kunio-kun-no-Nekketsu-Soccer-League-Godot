extends BallState

func enter(data: KickData) -> void:
	var attack_direction: Vector2 = data.direction
	var power: int = data.endurance + 10
	ball.set_receivable_detection_enabled(false)
	if not ball.is_in_air():
		ball.ball_z_movement.set_z_height(8)

	ball.ball_horizontal_movement.set_horizontal_velocity(
		attack_direction * 8
	)
	
	ball.prepare_ball_attack_hit(attack_direction,power,5)
	anim.play(anim_name)
	ball.ball_z_movement.pause_z_motion()
	ball.tick_timer_component.start_timer(
		"shot",
		18
	)
	await ball.tick_timer_component.timer_finished
	change_state(State.FREE)
func physics_tick() -> void:
	pass
func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

func physics_process(_delta: float) -> void:
	pass
