extends BallState
var elapsed_time: float = 0.0
var flat_fly_time: float = 0.5
func enter(params: Dictionary = {}) -> void:
	print("5点伤害")
	ball.z_height = 5
	elapsed_time = 0
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

func physics_process(delta: float) -> void:
	elapsed_time += delta
	
	ball.velocity = Vector2(ball.kick_power * ball.kick_direction,0)
	if elapsed_time >= flat_fly_time:
		change_state(State.FREE)
	pass
