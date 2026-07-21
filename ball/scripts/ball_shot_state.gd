extends BallState
var elapsed_time: float = 0.0
var flat_fly_time: float = 1.5
func enter() -> void:
	ball.pickup_area.set_deferred("monitorable", false)
	ball.z_axis_component.start_falling_from(68)
	elapsed_time = 0
	pass


func exit() -> void:
	ball.z_axis_component.force_step_falling()
	pass


func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	elapsed_time += delta
	
	ball.velocity = Vector2(ball.hit_box.hit_info["force"] * ball.hit_box.hit_info["direction"])
	if elapsed_time >= flat_fly_time:
		
		change_state(State.FREE)
	pass
