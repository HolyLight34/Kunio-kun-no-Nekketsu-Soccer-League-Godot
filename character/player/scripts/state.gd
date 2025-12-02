@icon("res://character/state.svg")
class_name State
extends Node
@onready var run: StateRun = %Run
@onready var jump: StateJump = %Jump
@onready var idle: StateIdle = %Idle
@onready var walk: StateWalk = %Walk


var player: Player
var nex_state: State = null

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
	
	
