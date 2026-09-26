extends BallState

func enter(_data) -> void:
	#ball.ball_interactable_area.enable()
	anim.play(anim_name)
	ball.ball_z_movement.resume_z_motion()
	if ball.stationary_flick_active:
		await ball.ball_z_movement.bounced
		ball.stationary_flick_active = false


func exit() -> void:
	pass

func physics_tick() -> void:
	pass
func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	
	pass
