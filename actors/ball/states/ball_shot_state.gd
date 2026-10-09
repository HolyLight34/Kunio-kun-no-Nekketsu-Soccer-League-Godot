extends BallState
const KICK_POSITION_OFFSET: float = 24.0
func enter(data: KickData) -> void:
	var power: int
	var attack_direction: Vector2 = data.direction
	var position_offset: Vector2 = (
		attack_direction
		* KICK_POSITION_OFFSET
	)

	ball.ball_horizontal_movement.set_horizontal_position(
		ball.get_logical_position()
		+ position_offset
	)
	ball.enable_hit()
	if ball.get_z_height() > 28:
		anim.play(anim_name)
		power  = data.endurance + 20
	else :
		if ball.is_in_air():
			power  = data.endurance + 10
		pass
	if not ball.is_in_air():
		ball.ball_z_movement.set_z_height(8)
	ball.set_receivable_detection_enabled(false)
	var goal_target := ball.get_goal_target_position(
		attack_direction
)

	var shot_direction := FCDirectionCalculator.calculate(
		ball.get_logical_position(),
		goal_target
)
	
	ball.ball_horizontal_movement.set_horizontal_velocity(
		shot_direction * 8
	)
	ball.prepare_ball_attack_hit(attack_direction,power,5)
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
	ball.disable_hit()
	ball.ball_z_movement.stop_height_hold()
	
