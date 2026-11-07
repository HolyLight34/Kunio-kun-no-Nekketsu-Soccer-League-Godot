@icon("res://entities/state.svg")
class_name EntityState
extends Node
## 获取状态编号，由子类实现
func get_state_id() -> int:
	return -1

signal transition_requested(
	from: EntityState,
	to: int,
	data: Variant
)
var actor: CharacterBody2D
@export var anim_name: StringName = &""
var anim: StepAnimationComponent:
	get:
		return actor.step_animation_component
# 虚函数：子类根据需要重写
## 当前状态下的 X 轴衰减率
@export var x_decel_rate: float = 0.0

func handle_intent(_intent: int) -> void:
	pass
	
func logic_tick() -> void:
	pass

## 请求切换到指定状态
func request_state(
	target_state_id: int,
	data: Variant = null
) -> void:
	transition_requested.emit(
		self,
		target_state_id,
		data
	)

func enter(data) -> void:
	pass


func exit()-> void:
	pass # 离开状态时（清理工作）

	# EntityState.gd (基类)
