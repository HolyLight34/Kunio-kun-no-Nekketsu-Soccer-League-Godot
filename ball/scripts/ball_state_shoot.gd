class_name BallStateShoot
extends BallState
var current_ball_position: Vector2
func init() -> void:
	pass
	
func enter() -> void:
	current_ball_position = ball.position
	pass
	
func exit() -> void:
	ball.player_data = {}
	pass

func handle_input(_event: InputEvent) -> BallState:
	return nex_state
	
func process(_delta: float) -> BallState:
	ball.position.x += 800 *_delta * ball.player_data["direction"].x
	if abs(ball.position.x - current_ball_position.x) >= 100:
		print("我运行了")
		return freeform
	return nex_state
	
func physics_process(_delta: float) -> BallState:
	return nex_state
