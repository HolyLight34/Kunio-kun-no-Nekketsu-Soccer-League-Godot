@icon("res://character/state.svg")
class_name BallState
extends Node
var ball: Ball
@onready var shot: BallStateShot = %Shot
@onready var freeform: BallStateFreeform = %Freeform
@onready var carried: BallStateCarried = %Carried

var nex_state: BallState = null

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
