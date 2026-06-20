
extends EntityState


# 虚函数：子类根据需要重写
func init():
	pass # 初始化（只运行一次）


func enter(params: Dictionary = {}):
	pass


func exit():
	pass # 离开状态时（清理工作）


# 处理逻辑并返回下一个状态（或返回 null 保持现状）
func physics_process(_delta: float) -> void:
	pass


func process(_delta: float) -> void:
	pass # 大多数时候返回 null


# 辅助函数：方便快速跳转
func get_state(state_name: String) -> State:
	return state_machine.state_pool.get(state_name.to_lower())
