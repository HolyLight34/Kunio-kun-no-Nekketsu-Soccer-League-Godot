extends BallState

func enter() -> void:
	ball.pickup_area.set_deferred("monitorable", true)
	ball.velocity = Vector2.ZERO
	#ball.action_component.play_action("idle")
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass


func physics_process(delta: float) -> void:
	
	pass
