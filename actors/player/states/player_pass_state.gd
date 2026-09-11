extends PlayerState

func enter(_data) -> void:
	#print(player.pass_target_detector.select_pass_target())
	var pass_trajectory_calculator := PassTrajectoryCalculator.new()
	var target_postion = player.pass_target_detector.get_pass_target_position()
	var pass_velocity: Vector3 = pass_trajectory_calculator.build_pass(
			player.carried_ball.get_logical_position(),
			target_postion
			)
	player.carried_ball.set_logical_velocity(pass_velocity)
	print("速度",pass_velocity)
	anim.play(anim_name)
	await anim.animation_finished
	change_state(State.IDLE)
	pass

func exit() -> void:
	
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(intent: int, _delta: float) -> void:
	
	pass
