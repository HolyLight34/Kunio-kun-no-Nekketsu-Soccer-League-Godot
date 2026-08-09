extends BallState
var elapsed_time: float = 0.0
var flat_fly_time: float = 1.5
@export var shoot_data: TickActionData
func enter() -> void:
	ball.pickup_area.set_deferred("monitorable", false)
	ball.action_driver_component.execute_action(shoot_data)
	await ball.action_driver_component.action_finished
	change_state(State.FREE)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	#elapsed_time += delta
	#
	#ball.velocity = Vector2(ball.hit_box.hit_info["force"] * ball.hit_box.hit_info["direction"])
	#if elapsed_time >= flat_fly_time:
		#
		#change_state(State.FREE)
	pass
