@icon("res://entities/state.svg")
class_name EntityState
extends Node

#var state_machine: StateMachine
signal transition_requested(from: EntityState, to: Variant)

var actor: CharacterBody2D


# 虚函数：子类根据需要重写
func init()-> void:
	pass # 初始化（只运行一次）

	
func handle_intent(_intent: int, _delta: float) -> void:
	pass


func change_state(target: Variant) -> void:
	transition_requested.emit(self, target)


func enter()-> void:
	pass


func exit()-> void:
	pass # 离开状态时（清理工作）

	# EntityState.gd (基类)




# 处理逻辑并返回下一个状态（或返回 null 保持现状）

func physics_process(_delta: float) -> void:
	pass


func process(_delta: float) -> void:
	pass # 大多数时候返回 null
