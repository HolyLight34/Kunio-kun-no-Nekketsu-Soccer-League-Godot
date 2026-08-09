extends PlayerState


func enter():
	change_state(State.IDLE)
	pass

func _on_action_stack_finished() -> void:
	# 动作自然结束时，立刻在当前逻辑帧切入 Idle 或下一个动作
	change_state(State.IDLE)
func exit() -> void:
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass
