extends BallState

func enter(params: Dictionary = {}) -> void:
	ball.z_height = 0
	ball.possession_changed.emit(ball.carrier)
	pass


func exit() -> void:
	ball.possession_lost.emit()
	ball.carrier = null
	pass


func process(_delta: float) -> void:
	pass


func physics_process(delta: float) -> void:
	var facing_sign = sign(ball.carrier.visual.scale.x)
	ball.global_position = ball.carrier.global_position + Vector2(ball.CARRY_OFFSET.x * facing_sign, ball.CARRY_OFFSET.y)
	pass
