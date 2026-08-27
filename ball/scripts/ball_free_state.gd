extends BallState

func enter() -> void:
	ball.pickup_area.set_deferred("monitorable", true)
	#print(ball.visual.position)
	#ball.speed_vector = Vector2.ZERO
	pass


func exit() -> void:
	pass
func calculate_fc_ball_deceleration_exact(current_speed: float) -> float:
	# 1. 低速阶段：固定阻力扣减 (每步扣除 32/256 = 0.125)
	if current_speed < 1.0:
		return move_toward(current_speed, 0.0, 0.125)
		
	# 2. 高速阶段：模拟 6502 汇编的 V - (V >> 4) - (V >> 5)
	var v_int := int(round(current_speed * 256.0))
	
	var shift_4 := v_int >> 4
	var shift_5 := v_int >> 5
	var next_v_int := v_int - shift_4 - shift_5
	
	return float(next_v_int) / 256.0
func physics_tick() -> void:
	ball.speed_vector.x = calculate_fc_ball_deceleration_exact(ball.speed_vector.x)
	pass
func process(_delta: float) -> void:
	pass


func physics_process(delta: float) -> void:
	
	pass
