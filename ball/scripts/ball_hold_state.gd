extends BallState

func enter() -> void:
	ball.pickup_area.set_deferred("monitorable", false)
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


func physics_process(_delta: float) -> void:
	var carrier_position = (
		ball.carrier.player_horizontal_movement.get_horizontal_position()
	)
	var anchor_offset := (
	ball.carrier.get_ball_anchor_offset()
)
	ball.ball_horizontal_component.set_horizontal_position(
		carrier_position + anchor_offset
	)
