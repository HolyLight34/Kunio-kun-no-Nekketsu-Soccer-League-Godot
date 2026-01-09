class_name BallStateFreeform
extends BallState
func init() -> void:
	pass
	
func enter() -> void:
	ball.kick_power = 0
	ball.kick_direction = Vector2.ZERO
	ball.z_height = 0
	pass
	
func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> BallState:
	return nex_state
	
func process(_delta: float) -> BallState:
	if ball.carrier:
		return carried
	if ball.kick_power != 0:
		return shoot
	return nex_state
	
func physics_process(delta: float) -> BallState:
	# 1. 处理垂直重力逻辑 (Z 轴)
	if ball.z_height > 0 or ball.z_speed != 0:
		ball.z_speed += ball.gravity * delta
		ball.z_height += ball.z_speed * delta
		# 落地判定
		if ball.z_height <= 0:
			ball.z_height = 0
			if abs(ball.z_speed) > 50: # 只有速度够快才反弹，防止无限微弱抖动
				ball.z_speed = -ball.z_speed * ball.bounce_factor
			else:
				ball.z_speed = 0
	ball.sprite_2d.position.y = -ball.z_height
	return nex_state
