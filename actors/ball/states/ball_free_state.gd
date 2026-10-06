extends BallState

func enter(_data) -> void:
	ball.ball_z_movement.gravity_enable()
	ball.release_from_carrier()
	ball.set_receivable_detection_enabled(true)
	anim.play(anim_name)
	


func exit() -> void:
	pass

func physics_tick() -> void:
	pass
func process(_delta: float) -> void:
	pass

func physics_process(_delta: float) -> void:
	
	pass
