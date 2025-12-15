class_name StateJump
extends State

func init() -> void:
	pass
	
func enter() -> void:
	pass
	
func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> State:
	return nex_state
	
func process(_delta: float) -> State:
	return nex_state
	
func physics_process(_delta: float) -> State:
	return nex_state
	
	
