class_name BallStateFreeform
extends BallState
func init() -> void:
	pass
	
func enter() -> void:
	pass
	
func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> BallState:
	return nex_state
	
func process(_delta: float) -> BallState:
	return nex_state
	
func physics_process(_delta: float) -> BallState:
	return nex_state
