extends BallState

func enter(data: KickData) -> void:
	var attack_direction: Vector2 = data.direction
	var power: int = data.endurance + 10
	ball.set_receivable_detection_enabled(false)
	var goal_target := ball.get_goal_target_position(
		attack_direction
)

	var shot_direction := FCDirectionCalculator.calculate(
		ball.get_logical_position(),
		goal_target
)
	if not ball.is_in_air():
		ball.ball_z_movement.set_z_height(8)

	ball.ball_horizontal_movement.set_horizontal_velocity(
		shot_direction * 8
	)
	
	ball.prepare_ball_attack_hit(attack_direction,power,5)
	anim.play(anim_name)
	ball.ball_z_movement.start_height_hold()
	ball.tick_timer_component.start_timer(
		"shot",
		18
	)
	await ball.tick_timer_component.timer_finished
	
	change_state(State.FREE)
func physics_tick() -> void:
	pass
func exit() -> void:
	ball.ball_z_movement.stop_height_hold()
	pass


func process(_delta: float) -> void:
	pass

func physics_process(_delta: float) -> void:
	pass
