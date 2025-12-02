@icon("res://character/state.svg")
class_name StateIdle
extends State

func init() -> void:
	pass
	
func enter() -> void:
	player.animation_player.play("idle")
	pass
	
func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> State:
	return nex_state
	
func process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		return walk
	return nex_state
	
func physics_process(_delta: float) -> State:
	return nex_state
	
	
