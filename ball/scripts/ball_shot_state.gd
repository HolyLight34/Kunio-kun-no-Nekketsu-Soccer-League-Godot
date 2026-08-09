extends BallState

func enter() -> void:
	ball.pickup_area.set_deferred("monitorable", false)
	
	change_state(State.FREE)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	pass
