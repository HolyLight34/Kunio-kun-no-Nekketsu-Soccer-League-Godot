@icon("res://character/state.svg")
class_name StateJump
extends Node

var character: Character
var nex_state: State

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
	
	
