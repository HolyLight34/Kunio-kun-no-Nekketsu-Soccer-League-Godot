@icon("res://entities/state.svg")
class_name EntityState
extends Node

#var state_machine: StateMachine
signal transition_requested(from: EntityState, to: Variant)
@export var windup_ticks: int = 0 
var actor: CharacterBody2D
@export var anim_name: StringName = &""
var anim: StepAnimationComponent:
	get:
		return actor.step_animation_component
# 虚函数：子类根据需要重写
func init()-> void:
	pass # 初始化（只运行一次）
## 当前状态下的 X 轴衰减率
@export var x_decel_rate: float = 0.0

## 🌟 状态内部调用：直接衰减当前状态配置的摩擦力
func apply_state_x_deceleration() -> void:
	if actor and x_decel_rate > 0.0:
		actor.apply_x_deceleration(x_decel_rate)
	
func handle_intent(_intent: int, _delta: float) -> void:
	pass
func physics_tick() -> void:
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
