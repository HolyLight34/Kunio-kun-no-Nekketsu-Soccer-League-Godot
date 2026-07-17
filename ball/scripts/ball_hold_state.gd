extends BallState

func enter() -> void:
	print("我执行了")
	ball.pickup_area.set_deferred("monitorable", false)
	ball.z_height = 0
	print(ball.carrier)
	ball.possession_changed.emit(ball.carrier)
	pass


func exit() -> void:
	ball.possession_lost.emit()
	if ball.sm.current_state != self:
		actor.possession_lost.emit()
		actor.carrier = null
		print("【HOLD 退出】球权真正移交，数据清理完毕")
	pass


func process(_delta: float) -> void:
	pass


func physics_process(delta: float) -> void:
	var facing_sign = sign(ball.carrier.visual.scale.x)
	ball.global_position = ball.carrier.global_position + Vector2(ball.CARRY_OFFSET.x * facing_sign, ball.CARRY_OFFSET.y)
	pass
