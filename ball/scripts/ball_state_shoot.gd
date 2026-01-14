class_name BallStateShoot
extends BallState

var current_ball_position: Vector2


func init() -> void:
	pass


func enter() -> void:
	ball.carrier = null
	current_ball_position = ball.position
	ball.collision_layer = 4
	pass


func exit() -> void:
	ball.collision_layer = 2
	pass


func handle_input(_event: InputEvent) -> BallState:
	return nex_state


func process(_delta: float) -> BallState:
	return nex_state


func physics_process(delta: float) -> BallState:
	ball.position.x += ball.kick_power * delta * ball.kick_direction.x
	ball.sprite_2d.position.y = -ball.z_height
	if abs(ball.position.x - current_ball_position.x) >= 100:
		return freeform
	return nex_state
