extends BallState

func enter(_data) -> void:
	pass


func exit() -> void:
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
	ball.ball_horizontal_movement.set_horizontal_position(
		carrier_position + anchor_offset
	)
