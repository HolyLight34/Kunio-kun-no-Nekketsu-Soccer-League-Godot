extends BallState

func enter(_data) -> void:
	anim.play(anim_name)
	ball.ball_z_movement.gravity_enabled = true
	pass


func exit() -> void:
	pass

func physics_tick() -> void:
	pass
func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	
	pass
