@icon("res://character/state.svg")
class_name BallState
extends Node

var ball: Ball

var nex_state: BallState = null

@onready var shoot: BallStateShoot = %Shoot
@onready var freeform: BallStateFreeform = %Freeform
@onready var carried: BallStateCarried = %Carried


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
