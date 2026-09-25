extends BallState

func enter(_data) -> void:
	ball.ball_z_movement.launch(8)
	ball.release_from_carrier()
	pass
func physics_tick() -> void:
	
	pass
func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

func physics_process(_delta: float) -> void:
	pass
