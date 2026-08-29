extends BallState

func enter() -> void:
	ball.pickup_area.set_deferred("monitorable", true)
	ball.ball_z_movement.grarty_entry = true
	pass


func exit() -> void:
	pass

func physics_tick() -> void:
	pass
func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	
	pass
